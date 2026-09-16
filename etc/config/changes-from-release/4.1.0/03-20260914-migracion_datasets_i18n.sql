-- =========================================================================
-- Migra datasets al esquema internacionalizado (i18n) directamente en BD,
-- sin pasar por la API de CKAN. Equivalente en SQL de
-- etc/config/changes-from-release/1.0.0/scripts/add_extras_i18n_mod.py
-- (en adelante "el script Python"), pero pensado para poder lanzarse sobre
-- TODA la base de datos de una sola pasada, sin API key y sin las
-- revalidaciones atomicas de package_patch que hoy tumban un dataset entero
-- por un solo campo mal formado (theme concatenado, frequency a '{}',
-- multilingual_tags corrupto...).
--
-- MODOS DE USO: se edita a mano el valor de _param.ids en el bloque 0, mas
-- abajo, antes de ejecutar. No depende de ningun mecanismo de variables de
-- cliente (nada de "-v" ni de bind parameters), asi que el script se
-- ejecuta igual en psql (psql -f fichero.sql), en DBeaver (pegar y ejecutar
-- como script) o en cualquier otro cliente SQL con soporte de bloques
-- DO $$...$$ (PL/pgSQL) y tablas temporales:
--
--   INSERT INTO _param VALUES ('');                          -- TODA la BD
--   INSERT INTO _param VALUES ('52b3ed88-...');               -- 1 dataset (id o slug)
--   INSERT INTO _param VALUES ('id-o-slug-1,id-o-slug-2');    -- lista de ids/slugs
--
-- Para el CSV de 1 columna que hoy consume "-l lista.csv" del script
-- Python, ver el bloque comentado "MODO CSV" justo debajo del bloque 0:
-- sustituye por completo a la forma de arriba.
--
-- CAMPOS CUBIERTOS (ver tabla completa de mapeo en el plan / PR asociado):
--   title_translated, description_translated, multilingual_tags,
--   publisher (ex publisher_uri), spatial (ex spatial_uri), theme,
--   language, frequency, y en recursos: name_translated / description_translated.
--
-- CAMPOS QUE NO NECESITAN MIGRACION: identifier y contact_email ya viven en
-- package_extra con la misma clave y el mismo formato (texto plano) que
-- usa el esquema i18n; el script Python solo los reenvia para que
-- package_patch no los pierda al reconstruir "extras" desde cero. Como aqui
-- no tocamos package_extra en bloque (solo las claves listadas arriba), no
-- hace falta ningun UPDATE para ellos.
--
-- POLITICA DE SOBRESCRITURA: idempotente. Solo se rellena lo que falta
-- (mismo criterio de "carecer de" que
-- 01-20260911-deteccion_datos_sin_internacionalizar.sql). Relanzar este
-- script sobre la misma BD no debe tocar filas ya migradas ni traducciones
-- ya cargadas en otros idiomas (en/ca/gl/eu).
--
-- QUE NO SE REPLICA DEL SCRIPT PYTHON (decisiones ya acordadas):
--   - El script Python envia "extras": [] en el patch, lo que en la API
--     borra TODOS los extras libres del dataset (guid, harvest_object_id,
--     dcat_*, source_hash...). Aqui NO se borra nada que no sea una de las
--     claves listadas arriba.
--   - El script Python reconstruye la lista "resources" sin "description",
--     y como esa columna es remove_if_not_provided, el patch la deja a
--     NULL. Aqui resource.name y resource.description NO se tocan; solo se
--     anaden las claves *_translated dentro de resource.extras.
--   - Si una etiqueta de frequency no esta en el mapa de 8 valores
--     conocidos, el script Python (via normalize_frequency) puede acabar
--     enviando "frequency": null, lo que el validador date_frequency
--     rechaza ("Expecting JSON object") y tumba el patch entero. Aqui esa
--     fila se deja intacta (no se escribe nada) y se reporta en
--     02/04 para revision manual -- no tiene sentido reproducir un caso que
--     en la API nunca llega a guardarse.
--   - theme/language: la validacion real (scheming_multiple_choice) solo
--     guarda el campo si TODOS los valores son choices conocidos; si hay
--     alguno desconocido, rechaza el patch entero y el dataset se queda sin
--     migrar. Aqui se replica ese todo-o-nada: si algun token no esta en el
--     esquema, la fila se deja intacta (no se escribe un array parcial) y
--     se reporta. Ademas, scheming_multiple_choice deduplica valores
--     repetidos (usa un set()) y siempre reordena segun el orden de
--     "choices" del esquema -- ambas cosas se replican aqui, porque eso es
--     lo que de verdad queda grabado en BD cuando la migracion via API
--     tiene exito (el JSON que reordena/deduplica lo genera el propio
--     validador servidor, no el script Python).
--
-- OTRAS DIFERENCIAS FRENTE A LA VIA API (no evitables, hay que actuar tras
-- el COMMIT):
--   - Este script NO reindexa Solr (igual que etc/config/changes-from-release/
--     4.0.0/02-20260824-migracion_tematicas_i18n_pkg_194d1360.sql y
--     4.0.0/04-20260824-deteccion_datasets_multiples_tematicas.sql). Tras el
--     COMMIT: "ckan search-index rebuild <package_id>"
--     por cada id de la lista que imprime el bloque 8, o un rebuild
--     completo si se migro toda la BD.
--   - No dispara los validadores del esquema ni los hooks de
--     IPackageController (no hay tags_html_detected, choices, required...).
--     Usar 04-20260914-verificacion_migracion_i18n.sql despues para
--     detectar lo que un guardado por API SI habria rechazado.
--   - No toca package.metadata_modified a proposito: bumpearlo alteraria
--     de golpe el orden de "actualizados recientemente" de todo el
--     catalogo si se migra en bloque.
-- =========================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 0) PARAMETRO + OBJETIVO: edita el valor de abajo antes de ejecutar.
--      ''                        -> TODA la BD
--      '<id-o-slug>'             -> 1 solo dataset
--      '<id1>,<id2>,<id3>'       -> lista de ids/slugs (separados por coma)
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
        pr.ids = ''                                                        -- '' en _param => TODA la BD
     OR p.id   = ANY (regexp_split_to_array(trim(pr.ids), '\s*,\s*'))       -- por id (uuid)
     OR p.name = ANY (regexp_split_to_array(trim(pr.ids), '\s*,\s*'))       -- o por slug
  );

-- MODO CSV (equivalente a "-l lista.csv" del script Python): en psql,
-- comentar el INSERT INTO _objetivo de arriba y descomentar estas 3
-- lineas (\copy es exclusivo de psql, no funciona en DBeaver/pgAdmin). El
-- CSV debe tener el id/slug del dataset como primer valor de cada fila
-- (igual que espera csv.reader en el script Python). En DBeaver/otros
-- clientes sin \copy: pega la lista completa de ids/slugs separados por
-- coma en el INSERT INTO _param de arriba, o usa la funcion de
-- importacion de datos del cliente para volcar el CSV directamente en
-- _objetivo(package_id).
--
-- TRUNCATE _objetivo;
-- \copy _objetivo(package_id) FROM 'datasets_migrar.csv' WITH (FORMAT csv)
-- DELETE FROM _objetivo o WHERE NOT EXISTS (
--     SELECT 1 FROM package p WHERE (p.id = o.package_id OR p.name = o.package_id)
--       AND p.state = 'active' AND p.type = 'dataset');

DO $$
DECLARE
    n_objetivo int;
    v_ids text;
BEGIN
    SELECT ids INTO v_ids FROM _param;
    SELECT count(*) INTO n_objetivo FROM _objetivo;
    IF n_objetivo = 0 THEN
        IF v_ids <> '' THEN
            RAISE EXCEPTION 'Ningun dataset activo coincide con _param.ids=%. Revisa los IDs/slugs.', v_ids;
        ELSE
            RAISE EXCEPTION 'No hay ningun dataset activo (state=active, type=dataset) en esta base de datos.';
        END IF;
    END IF;
    RAISE NOTICE 'Objetivo: % dataset(s)', n_objetivo;
END $$;

-- ---------------------------------------------------------------------
-- 1) TITLE_TRANSLATED / DESCRIPTION_TRANSLATED
--    Emula fluent_text: {"es": "<texto>"} (json.dumps ensure_ascii=False,
--    que coincide con la salida de texto de jsonb: mismas comillas y
--    separadores ", " / ": ", y los acentos se guardan literales en UTF-8
--    en ambos casos, no como secuencias \uXXXX).
--
--    Fallback de description (identico al script Python): si notes es
--    NULL se usa el title; si notes es '' (cadena vacia presente) se deja
--    tal cual, NO se sustituye por el title.
--
--    Objetivo = mismo criterio que 01-...-deteccion_datos_sin_internacionalizar.sql:
--    solo paquetes con title/notes reales y sin title_translated /
--    description_translated real todavia.
-- ---------------------------------------------------------------------

-- 1a) title_translated: falta la fila completa -> INSERT
INSERT INTO package_extra (id, package_id, key, value, state)
SELECT (md5(random()::text || clock_timestamp()::text))::uuid::text,
       p.id, 'title_translated',
       jsonb_build_object('es', COALESCE(p.title, ''))::text,
       'active'
FROM package p
JOIN _objetivo o ON o.package_id = p.id
WHERE COALESCE(TRIM(p.title), '') <> ''
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = p.id AND pe.key = 'title_translated'
  );

-- 1b) title_translated: la fila existe pero esta vacia -> UPDATE
UPDATE package_extra pe
SET value = jsonb_build_object('es', COALESCE(p.title, ''))::text
FROM package p
JOIN _objetivo o ON o.package_id = p.id
WHERE pe.package_id = p.id AND pe.key = 'title_translated'
  AND COALESCE(TRIM(p.title), '') <> ''
  AND (
        TRIM(pe.value) IN ('', '{}')
        OR pe.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
      );

-- 1c) description_translated: falta la fila completa -> INSERT
INSERT INTO package_extra (id, package_id, key, value, state)
SELECT (md5(random()::text || clock_timestamp()::text))::uuid::text,
       p.id, 'description_translated',
       jsonb_build_object('es', COALESCE(p.notes, p.title, ''))::text,
       'active'
FROM package p
JOIN _objetivo o ON o.package_id = p.id
WHERE COALESCE(TRIM(p.notes), '') <> ''
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = p.id AND pe.key = 'description_translated'
  );

-- 1d) description_translated: la fila existe pero esta vacia -> UPDATE
UPDATE package_extra pe
SET value = jsonb_build_object('es', COALESCE(p.notes, p.title, ''))::text
FROM package p
JOIN _objetivo o ON o.package_id = p.id
WHERE pe.package_id = p.id AND pe.key = 'description_translated'
  AND COALESCE(TRIM(p.notes), '') <> ''
  AND (
        TRIM(pe.value) IN ('', '{}')
        OR pe.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
      );

-- ---------------------------------------------------------------------
-- 2) MULTILINGUAL_TAGS: {"es": ["tag1","tag2"]} a partir de package_tag/tag.
--    Mismo patron que 01-20260622-migracion_etiquetas_i18n.sql (borrar
--    vacios + insertar), restringido a _objetivo y anadiendo el filtro de
--    nombre de tag valido del script Python (valid_tag_names /
--    _TAG_NAME_RE: 2-100 caracteres, letras/digitos/espacio/guion/
--    guion_bajo/punto) que el script 01 no aplicaba.
--    NOTA: el \w de Postgres depende de la collation/LC_CTYPE de la BD; en
--    la practica coincide con el \w de Python (re.UNICODE) para los tags
--    ya almacenados aqui (ASCII + acentos comunes es/ca/gl/eu).
-- ---------------------------------------------------------------------

DELETE FROM package_extra pe
USING _objetivo o
WHERE pe.package_id = o.package_id
  AND pe.key = 'multilingual_tags'
  AND (pe.value IS NULL OR pe.value = '' OR pe.value = '{}');

INSERT INTO package_extra (id, package_id, key, value, state)
SELECT
    (md5(random()::text || clock_timestamp()::text))::uuid::text,
    pt.package_id,
    'multilingual_tags',
    jsonb_build_object('es', jsonb_agg(t.name ORDER BY t.name))::text,
    'active'
FROM package_tag pt
JOIN tag t ON t.id = pt.tag_id
JOIN _objetivo o ON o.package_id = pt.package_id
WHERE pt.state = 'active'
  AND t.vocabulary_id IS NULL
  AND t.name ~ '^[\w \-\.]{2,100}$'
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = pt.package_id
        AND pe.key = 'multilingual_tags'
        AND pe.value IS NOT NULL AND pe.value <> '' AND pe.value <> '{}'
  )
GROUP BY pt.package_id;

-- ---------------------------------------------------------------------
-- 3) RENOMBRAR extras antiguos a sus nuevas claves del esquema i18n:
--    publisher_uri -> publisher ; spatial_uri -> spatial.
--    Solo se renombra si NO existe ya una fila con la clave nueva para ese
--    package (idempotente + respeta "solo rellenar lo que falta": si
--    publisher/spatial ya tienen valor propio, se deja intacto). Las
--    colisiones quedan reportadas en 02/04 para revision manual.
-- ---------------------------------------------------------------------

UPDATE package_extra pe_old
SET key = 'publisher'
FROM _objetivo o
WHERE pe_old.package_id = o.package_id
  AND pe_old.key = 'publisher_uri'
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe_new
      WHERE pe_new.package_id = pe_old.package_id AND pe_new.key = 'publisher'
  );

UPDATE package_extra pe_old
SET key = 'spatial'
FROM _objetivo o
WHERE pe_old.package_id = o.package_id
  AND pe_old.key = 'spatial_uri'
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe_new
      WHERE pe_new.package_id = pe_old.package_id AND pe_new.key = 'spatial'
  );

-- ---------------------------------------------------------------------
-- 4) THEME: de string separado por comas a array JSON ordenado segun
--    "choices" del esquema (ver schemas_templates/datasets.json), emulando
--    scheming_multiple_choice: reordena y --a diferencia del script
--    Python-- deduplica y NO acepta parcialmente: si algun token no es un
--    choice conocido, la fila se deja SIN TOCAR (igual que un patch real
--    que la API rechazaria entero por "unexpected choice"). Ver 02/04 para
--    los casos con tokens no reconocidos.
-- ---------------------------------------------------------------------

CREATE TEMP TABLE _orden_theme(valor text PRIMARY KEY, orden int) ON COMMIT DROP;
INSERT INTO _orden_theme(valor, orden) VALUES
    ('http://datos.gob.es/kos/sector-publico/sector/ciencia-tecnologia', 1),
    ('http://datos.gob.es/kos/sector-publico/sector/comercio', 2),
    ('http://datos.gob.es/kos/sector-publico/sector/cultura-ocio', 3),
    ('http://datos.gob.es/kos/sector-publico/sector/demografia', 4),
    ('http://datos.gob.es/kos/sector-publico/sector/deporte', 5),
    ('http://datos.gob.es/kos/sector-publico/sector/economia', 6),
    ('http://datos.gob.es/kos/sector-publico/sector/educacion', 7),
    ('http://datos.gob.es/kos/sector-publico/sector/empleo', 8),
    ('http://datos.gob.es/kos/sector-publico/sector/energia', 9),
    ('http://datos.gob.es/kos/sector-publico/sector/hacienda', 10),
    ('http://datos.gob.es/kos/sector-publico/sector/industria', 11),
    ('http://datos.gob.es/kos/sector-publico/sector/legislacion-justicia', 12),
    ('http://datos.gob.es/kos/sector-publico/sector/medio-ambiente', 13),
    ('http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca', 14),
    ('http://datos.gob.es/kos/sector-publico/sector/salud', 15),
    ('http://datos.gob.es/kos/sector-publico/sector/sector-publico', 16),
    ('http://datos.gob.es/kos/sector-publico/sector/seguridad', 17),
    ('http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar', 18),
    ('http://datos.gob.es/kos/sector-publico/sector/transporte', 19),
    ('http://datos.gob.es/kos/sector-publico/sector/turismo', 20),
    ('http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras', 21),
    ('http://datos.gob.es/kos/sector-publico/sector/vivienda', 22);

WITH tokens AS (
    SELECT DISTINCT pe.id AS extra_id, trim(tok) AS token
    FROM package_extra pe
    JOIN _objetivo o ON o.package_id = pe.package_id
    CROSS JOIN LATERAL unnest(string_to_array(pe.value, ',')) AS tok
    WHERE pe.key = 'theme'
      AND pe.value IS NOT NULL
      AND pe.value NOT LIKE '[%'
),
agregado AS (
    SELECT tk.extra_id,
           bool_and(oth.orden IS NOT NULL) AS todo_valido,
           jsonb_agg(oth.valor ORDER BY oth.orden) FILTER (WHERE oth.orden IS NOT NULL) AS nuevo_valor
    FROM tokens tk
    LEFT JOIN _orden_theme oth ON oth.valor = tk.token
    WHERE tk.token <> ''
    GROUP BY tk.extra_id
)
UPDATE package_extra pe
SET value = a.nuevo_valor::text
FROM agregado a
WHERE pe.id = a.extra_id AND a.todo_valido;

-- ---------------------------------------------------------------------
-- 5) LANGUAGE: misma mecanica que theme (tambien usa scheming_multiple_choice
--    vía el preset multiple_checkbox), con el orden de choices es/ca/gl/eu/en.
--    Acepta tanto "es,ca" (CSV, lo mas comun en extras antiguos) como un
--    unico codigo suelto "es" (sin comas).
-- ---------------------------------------------------------------------

CREATE TEMP TABLE _orden_language(valor text PRIMARY KEY, orden int) ON COMMIT DROP;
INSERT INTO _orden_language(valor, orden) VALUES
    ('es', 1),
    ('ca', 2),
    ('gl', 3),
    ('eu', 4),
    ('en', 5);

WITH tokens AS (
    SELECT DISTINCT pe.id AS extra_id, trim(tok) AS token
    FROM package_extra pe
    JOIN _objetivo o ON o.package_id = pe.package_id
    CROSS JOIN LATERAL unnest(string_to_array(pe.value, ',')) AS tok
    WHERE pe.key = 'language'
      AND pe.value IS NOT NULL
      AND pe.value NOT LIKE '[%'
),
agregado AS (
    SELECT tk.extra_id,
           bool_and(ol.orden IS NOT NULL) AS todo_valido,
           jsonb_agg(ol.valor ORDER BY ol.orden) FILTER (WHERE ol.orden IS NOT NULL) AS nuevo_valor
    FROM tokens tk
    LEFT JOIN _orden_language ol ON ol.valor = tk.token
    WHERE tk.token <> ''
    GROUP BY tk.extra_id
)
UPDATE package_extra pe
SET value = a.nuevo_valor::text
FROM agregado a
WHERE pe.id = a.extra_id AND a.todo_valido;

-- ---------------------------------------------------------------------
-- 6) FREQUENCY: de etiqueta en espanol a {"type": "...", "value": N}.
--    Emula normalize_frequency() del script Python:
--      - Si ya es un JSON {type,value} valido (type en la lista permitida
--        y value entero no vacio) -> no se toca (ya migrado).
--      - Si ya es un objeto JSON pero invalido/incompleto (p.ej. '{}') ->
--        se normaliza a {"type": "", "value": ""} para que el validador lo
--        siga aceptando.
--      - Si es una etiqueta en espanol del mapa de 8 valores -> se
--        convierte a {"type": tipo, "value": valor}.
--      - Si es una etiqueta NO mapeada -> se deja intacta (ver cabecera:
--        no se replica el envio de null que el script Python podria hacer
--        en ese caso, porque rompe el validador). Se reporta en 02/04.
-- ---------------------------------------------------------------------

CREATE TEMP TABLE _mapa_frecuencia(etiqueta text PRIMARY KEY, tipo text, valor int) ON COMMIT DROP;
INSERT INTO _mapa_frecuencia(etiqueta, tipo, valor) VALUES
    ('anual', 'years', 1),
    ('semestral', 'months', 6),
    ('trimestral', 'months', 3),
    ('bimensual', 'months', 2),
    ('mensual', 'months', 1),
    ('quincenal', 'days', 15),
    ('semanal', 'days', 7),
    ('diaria', 'days', 1);

CREATE TEMP TABLE _frecuencia_nueva(id text PRIMARY KEY, value_nuevo text) ON COMMIT DROP;

INSERT INTO _frecuencia_nueva(id, value_nuevo)
SELECT pe.id,
    CASE
      WHEN pe.value ~ '^\s*\{.*\}\s*$' THEN
        CASE
          WHEN (pe.value::jsonb ? 'type') AND (pe.value::jsonb ? 'value')
               AND (pe.value::jsonb ->> 'type') IN ('days','weeks','months','years','hours','minutes','seconds')
               AND (pe.value::jsonb ->> 'value') ~ '^\d+$'
            THEN NULL                                    -- ya valido, no tocar
          ELSE '{"type": "", "value": ""}'                -- dict roto/incompleto
        END
      ELSE (
        SELECT jsonb_build_object('type', m.tipo, 'value', m.valor)::text
        FROM _mapa_frecuencia m
        WHERE m.etiqueta = lower(trim(pe.value))
      )                                                   -- NULL si la etiqueta no esta mapeada
    END
FROM package_extra pe
JOIN _objetivo o ON o.package_id = pe.package_id
WHERE pe.key = 'frequency';

UPDATE package_extra pe
SET value = n.value_nuevo
FROM _frecuencia_nueva n
WHERE pe.id = n.id
  AND n.value_nuevo IS NOT NULL
  AND pe.value IS DISTINCT FROM n.value_nuevo;

-- ---------------------------------------------------------------------
-- 7) RECURSOS: name_translated / description_translated dentro de
--    resource.extras (columna JsonDictType). resource.name y
--    resource.description NO se tocan (decision acordada, ver cabecera).
--
--    El merge con "||" preserva cualquier otra clave que ya hubiera en
--    extras (harvest, dcat_*, etc.), y solo se escribe la clave que
--    realmente falta (mismo criterio de "carecer de" que
--    01-...-deteccion_datos_sin_internacionalizar.sql a nivel de recurso).
--
--    Los jsonb_build_object anidados llevan "::text" porque en CKAN cada
--    campo fluent se guarda como STRING JSON dentro del JSON de extras
--    (fluent_text hace json.dumps() antes de que convert_to_extras lo
--    meta en el dict de extras), no como objeto anidado -- de ahi que
--    01-...sql tenga que leerlo con "->>": y no "->".
-- ---------------------------------------------------------------------

-- 7a) name_translated
UPDATE resource r
SET extras = (
      COALESCE(CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::jsonb END, '{}'::jsonb)
      || jsonb_build_object('name_translated', jsonb_build_object('es', r.name)::text)
    )::text
FROM _objetivo o
WHERE r.package_id = o.package_id
  AND r.state = 'active'
  AND COALESCE(TRIM(r.name), '') <> ''
  AND (
        (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) IS NULL
        OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END)) IN ('', '{}')
        OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
      );

-- 7b) description_translated (fallback a r.name solo si r.description es
--     NULL, igual que el script Python; si es '' se guarda vacio tal cual).
UPDATE resource r
SET extras = (
      COALESCE(CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::jsonb END, '{}'::jsonb)
      || jsonb_build_object('description_translated', jsonb_build_object('es', COALESCE(r.description, r.name))::text)
    )::text
FROM _objetivo o
WHERE r.package_id = o.package_id
  AND r.state = 'active'
  AND COALESCE(TRIM(r.description), '') <> ''
  AND (
        (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) IS NULL
        OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END)) IN ('', '{}')
        OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
      );

-- ---------------------------------------------------------------------
-- 8) RESUMEN final (antes del COMMIT): que queda pendiente en _objetivo, y
--    la lista de package_id para reindexar Solr despues.
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

-- Lista de datasets tocados en esta ejecucion (para "ckan search-index
-- rebuild <package_id>" tras el COMMIT; o un rebuild completo si no se
-- paso -v ids).
SELECT o.package_id, p.name
FROM _objetivo o
JOIN package p ON p.id = o.package_id
ORDER BY p.name;

COMMIT;
