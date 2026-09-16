-- =========================================================================
-- Inventario PREVIO a 03-20260914-migracion_datasets_i18n.sql. Solo
-- lectura: no modifica nada. Pensado para correr antes de la migracion y
-- saber exactamente contra que nos enfrentamos: cuantos datasets le falta
-- cada campo, y sobre todo cuales van a quedar SIN migrar automaticamente
-- porque algun valor no encaja con el esquema (theme/language/frequency
-- con tokens desconocidos, colisiones de extras renombrados...).
--
-- Admite los mismos modos que 03-...sql: se edita a mano el valor de
-- _param.ids en el bloque 0, mas abajo. No depende de ningun mecanismo de
-- variables de cliente, asi que funciona igual en psql (psql -f
-- fichero.sql), en DBeaver (pegar y ejecutar como script) o en cualquier
-- otro cliente SQL con soporte de bloques DO $$...$$ (PL/pgSQL) y tablas
-- temporales:
--   ''                        -> inventario de TODA la BD
--   '<id-o-slug>'             -> inventario de 1 dataset
--   '<id1>,<id2>,<id3>'       -> inventario de una lista
--
-- Usa temp tables, por eso va envuelto en BEGIN/COMMIT (a diferencia de
-- 01-20260911-deteccion_datos_sin_internacionalizar.sql, que al no usar
-- temp tables no lo necesitaba). Al ser todo SELECT, el COMMIT final no
-- persiste ningun cambio.
-- =========================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0) PARAMETRO + OBJETIVO: edita el valor de abajo antes de ejecutar.
-- ---------------------------------------------------------------------
CREATE TEMP TABLE _param(ids text) ON COMMIT DROP;
INSERT INTO _param VALUES ('');                          -- <-- EDITAR AQUI

CREATE TEMP TABLE _objetivo(package_id text PRIMARY KEY) ON COMMIT DROP;

INSERT INTO _objetivo(package_id)
SELECT p.id
FROM package p
CROSS JOIN _param pr
WHERE p.state = 'active' AND p.type = 'dataset'
  AND (
        pr.ids = ''
     OR p.id   = ANY (regexp_split_to_array(trim(pr.ids), '\s*,\s*'))
     OR p.name = ANY (regexp_split_to_array(trim(pr.ids), '\s*,\s*'))
  );

-- MODO CSV: ver 03-20260914-migracion_datasets_i18n.sql, mismo patron (en
-- psql, con \copy; en DBeaver/otros clientes, pegando la lista de ids en
-- el INSERT INTO _param de arriba o importando el CSV directamente en
-- _objetivo).

DO $$
DECLARE
    n_objetivo int;
    v_ids text;
BEGIN
    SELECT ids INTO v_ids FROM _param;
    SELECT count(*) INTO n_objetivo FROM _objetivo;
    RAISE NOTICE 'Objetivo: % dataset(s) (ids=%)', n_objetivo,
        CASE WHEN v_ids = '' THEN '<toda la BD>' ELSE v_ids END;
END $$;

-- ---------------------------------------------------------------------
-- 1) RESUMEN: tamano del problema por campo, dentro del objetivo.
-- ---------------------------------------------------------------------
SELECT
    count(*) AS total_objetivo,
    count(*) FILTER (WHERE te.value IS NULL OR TRIM(te.value) IN ('', '{}')
        OR te.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$')          AS falta_title_translated,
    count(*) FILTER (WHERE de.value IS NULL OR TRIM(de.value) IN ('', '{}')
        OR de.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$')          AS falta_description_translated,
    count(*) FILTER (WHERE th.value IS NOT NULL AND th.value NOT LIKE '[%')       AS theme_sin_migrar,
    count(*) FILTER (WHERE la.value IS NOT NULL AND la.value NOT LIKE '[%')       AS language_sin_migrar,
    count(*) FILTER (WHERE fr.value IS NOT NULL AND fr.value NOT LIKE '{%')       AS frequency_sin_migrar
FROM _objetivo o
LEFT JOIN package_extra te ON te.package_id = o.package_id AND te.key = 'title_translated'
LEFT JOIN package_extra de ON de.package_id = o.package_id AND de.key = 'description_translated'
LEFT JOIN package_extra th ON th.package_id = o.package_id AND th.key = 'theme'
LEFT JOIN package_extra la ON la.package_id = o.package_id AND la.key = 'language'
LEFT JOIN package_extra fr ON fr.package_id = o.package_id AND fr.key = 'frequency';

-- ---------------------------------------------------------------------
-- 2) THEME: valores todavia en formato antiguo (string separado por
--    comas), separando los que 03-...sql migrara sin problema de los que
--    dejara intactos por tener algun token que no es un choice conocido
--    del esquema (schemas_templates/datasets.json).
-- ---------------------------------------------------------------------
WITH _choices_theme(valor) AS (VALUES
    ('http://datos.gob.es/kos/sector-publico/sector/ciencia-tecnologia'),
    ('http://datos.gob.es/kos/sector-publico/sector/comercio'),
    ('http://datos.gob.es/kos/sector-publico/sector/cultura-ocio'),
    ('http://datos.gob.es/kos/sector-publico/sector/demografia'),
    ('http://datos.gob.es/kos/sector-publico/sector/deporte'),
    ('http://datos.gob.es/kos/sector-publico/sector/economia'),
    ('http://datos.gob.es/kos/sector-publico/sector/educacion'),
    ('http://datos.gob.es/kos/sector-publico/sector/empleo'),
    ('http://datos.gob.es/kos/sector-publico/sector/energia'),
    ('http://datos.gob.es/kos/sector-publico/sector/hacienda'),
    ('http://datos.gob.es/kos/sector-publico/sector/industria'),
    ('http://datos.gob.es/kos/sector-publico/sector/legislacion-justicia'),
    ('http://datos.gob.es/kos/sector-publico/sector/medio-ambiente'),
    ('http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca'),
    ('http://datos.gob.es/kos/sector-publico/sector/salud'),
    ('http://datos.gob.es/kos/sector-publico/sector/sector-publico'),
    ('http://datos.gob.es/kos/sector-publico/sector/seguridad'),
    ('http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar'),
    ('http://datos.gob.es/kos/sector-publico/sector/transporte'),
    ('http://datos.gob.es/kos/sector-publico/sector/turismo'),
    ('http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras'),
    ('http://datos.gob.es/kos/sector-publico/sector/vivienda')
),
tokens AS (
    SELECT pe.package_id, pe.value AS valor_actual, trim(tok) AS token
    FROM package_extra pe
    JOIN _objetivo o ON o.package_id = pe.package_id
    CROSS JOIN LATERAL unnest(string_to_array(pe.value, ',')) AS tok
    WHERE pe.key = 'theme' AND pe.value IS NOT NULL AND pe.value NOT LIKE '[%'
)
SELECT
    p.name AS dataset_slug,
    tk.package_id,
    tk.valor_actual,
    array_agg(tk.token ORDER BY tk.token) FILTER (WHERE tk.token <> '' AND ct.valor IS NULL) AS tokens_no_reconocidos
FROM tokens tk
LEFT JOIN _choices_theme ct ON ct.valor = tk.token
JOIN package p ON p.id = tk.package_id
GROUP BY p.name, tk.package_id, tk.valor_actual
ORDER BY tokens_no_reconocidos IS NOT NULL DESC, p.name;

-- ---------------------------------------------------------------------
-- 3) LANGUAGE: misma logica que el bloque anterior (choices es/ca/gl/eu/en).
-- ---------------------------------------------------------------------
WITH _choices_language(valor) AS (VALUES ('es'), ('ca'), ('gl'), ('eu'), ('en')),
tokens AS (
    SELECT pe.package_id, pe.value AS valor_actual, trim(tok) AS token
    FROM package_extra pe
    JOIN _objetivo o ON o.package_id = pe.package_id
    CROSS JOIN LATERAL unnest(string_to_array(pe.value, ',')) AS tok
    WHERE pe.key = 'language' AND pe.value IS NOT NULL AND pe.value NOT LIKE '[%'
)
SELECT
    p.name AS dataset_slug,
    tk.package_id,
    tk.valor_actual,
    array_agg(tk.token ORDER BY tk.token) FILTER (WHERE tk.token <> '' AND cl.valor IS NULL) AS tokens_no_reconocidos
FROM tokens tk
LEFT JOIN _choices_language cl ON cl.valor = tk.token
JOIN package p ON p.id = tk.package_id
GROUP BY p.name, tk.package_id, tk.valor_actual
ORDER BY tokens_no_reconocidos IS NOT NULL DESC, p.name;

-- ---------------------------------------------------------------------
-- 4) FREQUENCY: valores todavia en formato antiguo (no empieza por '{'),
--    marcando cuales SI estan en el mapa de 8 etiquetas conocidas y
--    cuales no (estos ultimos se dejaran intactos en 03-...sql).
-- ---------------------------------------------------------------------
WITH _mapa(etiqueta) AS (VALUES
    ('anual'), ('semestral'), ('trimestral'), ('bimensual'),
    ('mensual'), ('quincenal'), ('semanal'), ('diaria')
)
SELECT
    p.name AS dataset_slug,
    pe.package_id,
    pe.value AS valor_actual,
    (m.etiqueta IS NOT NULL) AS etiqueta_mapeable
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
JOIN package p ON p.id = pe.package_id
LEFT JOIN _mapa m ON m.etiqueta = lower(trim(pe.value))
WHERE pe.key = 'frequency' AND pe.value IS NOT NULL AND pe.value NOT LIKE '{%'
ORDER BY etiqueta_mapeable, p.name;

-- ---------------------------------------------------------------------
-- 5) Colisiones de extras a renombrar: datasets con la clave antigua Y la
--    nueva a la vez (publisher_uri+publisher, spatial_uri+spatial). 03-...sql
--    NO renombrara la antigua en estos casos (deja la nueva intacta);
--    revisar a mano cual de los dos valores es el correcto.
-- ---------------------------------------------------------------------
SELECT
    p.name AS dataset_slug,
    old_e.package_id,
    old_e.key AS clave_antigua, old_e.value AS valor_antiguo,
    new_e.key AS clave_nueva,   new_e.value AS valor_nuevo
FROM package_extra old_e
JOIN _objetivo o ON o.package_id = old_e.package_id
JOIN package p ON p.id = old_e.package_id
JOIN package_extra new_e
    ON new_e.package_id = old_e.package_id
   AND (
        (old_e.key = 'publisher_uri' AND new_e.key = 'publisher')
     OR (old_e.key = 'spatial_uri'   AND new_e.key = 'spatial')
       )
ORDER BY p.name, old_e.key;

-- ---------------------------------------------------------------------
-- 6) Recursos cuyo "extras" no es JSON parseable (guard igual que
--    01-...sql): 03-...sql los trata como "sin extras previos" ('{}') y
--    escribe encima; si de verdad tenian contenido corrupto pero
--    recuperable, revisar antes de migrar.
-- ---------------------------------------------------------------------
SELECT
    p.name AS dataset_slug,
    r.package_id,
    r.id AS resource_id,
    r.name AS resource_name,
    r.extras AS extras_raw
FROM resource r
JOIN _objetivo o ON o.package_id = r.package_id
JOIN package p ON p.id = r.package_id
WHERE r.state = 'active'
  AND r.extras IS NOT NULL
  AND r.extras !~ '^\s*\{.*\}\s*$'
ORDER BY p.name, r.name;

-- ---------------------------------------------------------------------
-- 7) Tags activos que el filtro de nombre valido de multilingual_tags
--    (_TAG_NAME_RE: 2-100 caracteres, letras/digitos/espacio/guion/
--    guion_bajo/punto) excluiria -- para que no sorprenda ver menos tags
--    en multilingual_tags que en el listado core de tags del dataset.
-- ---------------------------------------------------------------------
SELECT
    p.name AS dataset_slug,
    pt.package_id,
    t.name AS tag_excluido
FROM package_tag pt
JOIN tag t ON t.id = pt.tag_id
JOIN _objetivo o ON o.package_id = pt.package_id
JOIN package p ON p.id = pt.package_id
WHERE pt.state = 'active'
  AND t.vocabulary_id IS NULL
  AND t.name !~ '^[\w \-\.]{2,100}$'
ORDER BY p.name, t.name;

COMMIT;
