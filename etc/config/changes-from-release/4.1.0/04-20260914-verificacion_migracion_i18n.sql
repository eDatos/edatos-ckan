-- =========================================================================
-- Verificacion POSTERIOR a 03-20260914-migracion_datasets_i18n.sql. Solo
-- lectura: no modifica nada. Pensado para correr despues de la migracion
-- (o en cualquier momento, para auditar el estado actual).
--
-- Cubre dos cosas distintas:
--   A) Lo que 03-...sql pudo dejar pendiente (mismo criterio de "carecer
--      de" que 01-20260911-deteccion_datos_sin_internacionalizar.sql,
--      que sigue siendo la referencia completa -- ejecutarlo tambien,
--      sin scoping, para ver el estado global del catalogo).
--   B) Validaciones que SOLO corren via API/formulario (tags_html_detected,
--      "theme" obligatorio, choices de theme/language) y que la via SQL
--      nunca dispara. Sirven para saber, sin tener que abrir el formulario
--      de cada dataset, cuales fallarian si alguien los reguardara ahora.
--
-- Admite los mismos modos que 03-...sql: se edita a mano el valor de
-- _param.ids en el bloque 0, mas abajo. No depende de ningun mecanismo de
-- variables de cliente, asi que funciona igual en psql (psql -f
-- fichero.sql), en DBeaver (pegar y ejecutar como script) o en cualquier
-- otro cliente SQL con soporte de bloques DO $$...$$ (PL/pgSQL) y tablas
-- temporales:
--   ''                        -> TODA la BD
--   '<id-o-slug>'             -> 1 dataset
--   '<id1>,<id2>'             -> lista de ids/slugs
--
-- Usa temp tables, por eso va envuelto en BEGIN/COMMIT (igual que
-- 02-20260914-inventario_previo_migracion_i18n.sql). Al ser todo SELECT,
-- el COMMIT final no persiste ningun cambio.
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
-- A) PENDIENTES: debe dar 0 en todo si el objetivo ya esta migrado por
--    completo. Mismos predicados que el bloque 8 de 03-...sql y el
--    resumen de 02-...sql.
-- ---------------------------------------------------------------------
SELECT
    count(*) AS total_objetivo,
    count(*) FILTER (WHERE te.value IS NULL OR TRIM(te.value) IN ('', '{}')
        OR te.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$')          AS pendiente_title_translated,
    count(*) FILTER (WHERE de.value IS NULL OR TRIM(de.value) IN ('', '{}')
        OR de.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$')          AS pendiente_description_translated,
    count(*) FILTER (WHERE th.value IS NOT NULL AND th.value NOT LIKE '[%')       AS pendiente_theme,
    count(*) FILTER (WHERE la.value IS NOT NULL AND la.value NOT LIKE '[%')       AS pendiente_language,
    count(*) FILTER (WHERE fr.value IS NOT NULL AND fr.value NOT LIKE '{%')       AS pendiente_frequency
FROM _objetivo o
LEFT JOIN package_extra te ON te.package_id = o.package_id AND te.key = 'title_translated'
LEFT JOIN package_extra de ON de.package_id = o.package_id AND de.key = 'description_translated'
LEFT JOIN package_extra th ON th.package_id = o.package_id AND th.key = 'theme'
LEFT JOIN package_extra la ON la.package_id = o.package_id AND la.key = 'language'
LEFT JOIN package_extra fr ON fr.package_id = o.package_id AND fr.key = 'frequency';

-- Recursos con name/description_translated aun pendientes.
SELECT count(*) AS recursos_pendientes
FROM resource r
JOIN _objetivo o ON o.package_id = r.package_id
WHERE r.state = 'active'
  AND (
        (COALESCE(TRIM(r.name), '') <> ''
            AND (
                  (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) IS NULL
                  OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END)) IN ('', '{}')
                  OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
                )
        )
        OR
        (COALESCE(TRIM(r.description), '') <> ''
            AND (
                  (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) IS NULL
                  OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END)) IN ('', '{}')
                  OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
                )
        )
      );

-- ---------------------------------------------------------------------
-- B1) CORRUPCION: filas que 03-...sql SI escribe/toca y que no tienen la
--    forma basica de JSON esperada (objeto o array). Comprobacion de
--    texto, no un parseo JSON real (mismo enfoque, y misma limitacion, que
--    01-...sql de esta carpeta y que etc/config/changes-from-release/4.0.0/
--    07-20260902-deteccion_datasets_sin_traducciones.sql) -- cualquier fila
--    aqui es sospechosa de corrupcion y merece mirarse a mano.
-- ---------------------------------------------------------------------
SELECT p.name AS dataset_slug, pe.package_id, pe.key, pe.value
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
JOIN package p ON p.id = pe.package_id
WHERE pe.key IN ('title_translated', 'description_translated', 'multilingual_tags', 'theme', 'language', 'frequency')
  AND pe.value IS NOT NULL
  AND pe.value !~ '^\s*[\{\[].*[\}\]]\s*$'
ORDER BY p.name, pe.key;

-- ---------------------------------------------------------------------
-- B2) HTML detectado en title_translated / description_translated:
--    tags_html_detected (BeautifulSoup) rechazaria estos datasets en
--    cuanto alguien reguarde el formulario. Aqui se emula con una
--    heuristica de regex (busca "<algo>"), no un parseo HTML real -- puede
--    dar falsos positivos con un simple "<" suelto en el texto.
-- ---------------------------------------------------------------------
SELECT p.name AS dataset_slug, pe.package_id, pe.key, pe.value
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
JOIN package p ON p.id = pe.package_id
WHERE pe.key IN ('title_translated', 'description_translated')
  AND pe.value ~ '<[a-zA-Z/][^<>]*>'
ORDER BY p.name, pe.key;

-- ---------------------------------------------------------------------
-- B3) THEME obligatorio: el esquema marca "theme" como required: true
--    (schemas_templates/datasets.json). Estos datasets guardarian bien
--    hoy en BD, pero el formulario de edicion pedira elegir una tematica
--    en cuanto alguien intente reguardarlos.
-- ---------------------------------------------------------------------
SELECT p.name AS dataset_slug, o.package_id,
       th.value AS theme_actual
FROM _objetivo o
JOIN package p ON p.id = o.package_id
LEFT JOIN package_extra th ON th.package_id = o.package_id AND th.key = 'theme'
WHERE th.value IS NULL OR th.value = '[]';

-- ---------------------------------------------------------------------
-- B4) THEME/LANGUAGE ya en formato array pero con elementos fuera de las
--    "choices" del esquema (por ejemplo, cargados por harvest o edicion
--    manual directa en BD, no por 03-...sql -- ese script nunca deja un
--    array con valores invalidos). Un reguardado por API fallaria con
--    "unexpected choice".
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
)
SELECT p.name AS dataset_slug, pe.package_id, pe.value AS theme_actual,
       array_agg(elem ORDER BY elem) AS valores_invalidos
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
JOIN package p ON p.id = pe.package_id
CROSS JOIN LATERAL jsonb_array_elements_text(pe.value::jsonb) AS elem
LEFT JOIN _choices_theme ct ON ct.valor = elem
WHERE pe.key = 'theme'
  AND pe.value LIKE '[%'
  AND pe.value ~ '^\s*\[.*\]\s*$'
  AND ct.valor IS NULL
GROUP BY p.name, pe.package_id, pe.value;

WITH _choices_language(valor) AS (VALUES ('es'), ('ca'), ('gl'), ('eu'), ('en'))
SELECT p.name AS dataset_slug, pe.package_id, pe.value AS language_actual,
       array_agg(elem ORDER BY elem) AS valores_invalidos
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
JOIN package p ON p.id = pe.package_id
CROSS JOIN LATERAL jsonb_array_elements_text(pe.value::jsonb) AS elem
LEFT JOIN _choices_language cl ON cl.valor = elem
WHERE pe.key = 'language'
  AND pe.value LIKE '[%'
  AND pe.value ~ '^\s*\[.*\]\s*$'
  AND cl.valor IS NULL
GROUP BY p.name, pe.package_id, pe.value;

COMMIT;
