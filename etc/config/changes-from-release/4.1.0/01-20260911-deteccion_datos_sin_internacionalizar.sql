-- =========================================================================
-- Detecta paquetes y recursos activos que NO están internacionalizados:
--   - datasets con title/notes/tags "core" pero sin su equivalente
--     traducido (title_translated / description_translated /
--     multilingual_tags en package_extra)
--   - recursos con name/description "core" pero sin su equivalente
--     traducido (name_translated / description_translated dentro del JSON
--     de resource.extras)
--
-- Complementa a etc/config/changes-from-release/4.0.0/
-- 07-20260902-deteccion_datasets_sin_traducciones.sql, que solo cubre
-- title_translated/description_translated a nivel de dataset. Este
-- script añade tags y recursos.
--
-- SUPUESTOS A VERIFICAR ANTES DE USAR:
--   1. Las keys en package_extra son 'title_translated',
--      'description_translated' y 'multilingual_tags'; las keys dentro
--      del JSON de resource.extras son 'name_translated' y
--      'description_translated'. Ajusta los literales si difieren en tu
--      esquema (ver ckanext-edatosscheming/ckanext/edatosscheming/
--      schemas_templates/datasets.json).
--   2. "Carecer de" para title/description (dataset y recurso) = no
--      existe la fila/clave, o el JSON guardado no tiene ningún valor no
--      vacío para ningún idioma. El chequeo se hace con una comprobación
--      de texto (regex), no con un parseo JSON real -- revisa el
--      resultado, puede haber falsos negativos si el JSON tiene
--      espacios/formato distinto al esperado ({"es":"...",...}).
--   3. "Carecer de" para multilingual_tags = no existe la fila, está
--      vacía ('{}'), o solo tiene arrays vacíos por idioma (p.ej.
--      {"es": []}). Solo se marca como "falta" si el dataset SÍ tiene
--      al menos un tag core activo (si no tiene tags en absoluto, no
--      hay nada que traducir).
--   4. resource.extras se guarda como texto JSON en una columna
--      UnicodeText (ver ckan/ckan/model/resource.py), y cada campo
--      fluent dentro de ese JSON se guarda a su vez como un JSON
--      serializado en texto (mismo formato que package_extra.value), de
--      ahí el cast ::json y el acceso con ->> en lugar de ->. El cast va
--      envuelto en un CASE que solo lo intenta si el texto "parece" un
--      objeto JSON ({...}), para no abortar la consulta si algún recurso
--      tiene extras corruptos/no-JSON -- en ese caso se trata como "sin
--      traducir".
--   5. Solo se consideran datasets/recursos activos
--      (state = 'active', package.type = 'dataset'). Ajusta los filtros
--      state/type si quieres incluir borradores, eliminados o showcases.
--   6. La sección 4 es una heurística en BD para el síntoma visto en
--      package_search de datasets con num_resources/num_tags > 0 pero
--      con los arrays resources/tags/extras/groups vacíos en el JSON
--      indexado. Ese síntoma vive en el índice Solr (el snapshot del
--      dict se captura al indexar), no en Postgres, así que esta
--      consulta NO confirma el estado real del índice -- solo localiza,
--      en BD, los datasets con recursos y tags reales que a la vez no
--      están internacionalizados en absoluto (sin title_translated NI
--      description_translated NI multilingual_tags), que es el
--      candidato más probable a fallar a medio construir el dict
--      durante la reindexación. Confirma cada candidato con
--      package_search antes de actuar, y valora reindexar
--      (`ckan search-index rebuild <id>`) los que se confirmen.
-- =========================================================================

-- 1) Resumen: tamaño del problema por tipo de campo
SELECT
    (SELECT COUNT(*) FROM package p
        WHERE p.state = 'active' AND p.type = 'dataset'
          AND COALESCE(TRIM(p.title), '') <> ''
          AND NOT EXISTS (
              SELECT 1 FROM package_extra pe
              WHERE pe.package_id = p.id
                AND pe.key = 'title_translated'
                AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
                AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
          )
    ) AS n_falta_title_translated,

    (SELECT COUNT(*) FROM package p
        WHERE p.state = 'active' AND p.type = 'dataset'
          AND COALESCE(TRIM(p.notes), '') <> ''
          AND NOT EXISTS (
              SELECT 1 FROM package_extra pe
              WHERE pe.package_id = p.id
                AND pe.key = 'description_translated'
                AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
                AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
          )
    ) AS n_falta_description_translated,

    (SELECT COUNT(DISTINCT pt.package_id)
        FROM package_tag pt
        JOIN package p ON p.id = pt.package_id
        WHERE pt.state = 'active'
          AND p.state = 'active' AND p.type = 'dataset'
          AND NOT EXISTS (
              SELECT 1 FROM package_extra pe
              WHERE pe.package_id = pt.package_id
                AND pe.key = 'multilingual_tags'
                AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
                AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*\[\s*\]\s*,?\s*)*\}\s*$'
          )
    ) AS n_falta_multilingual_tags,

    (SELECT COUNT(*) FROM resource r
        JOIN package p ON p.id = r.package_id
        WHERE r.state = 'active'
          AND p.state = 'active' AND p.type = 'dataset'
          AND COALESCE(TRIM(r.name), '') <> ''
          AND (
                (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) IS NULL
                OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END)) IN ('', '{}')
                OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
              )
    ) AS n_falta_name_translated_recursos,

    (SELECT COUNT(*) FROM resource r
        JOIN package p ON p.id = r.package_id
        WHERE r.state = 'active'
          AND p.state = 'active' AND p.type = 'dataset'
          AND COALESCE(TRIM(r.description), '') <> ''
          AND (
                (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) IS NULL
                OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END)) IN ('', '{}')
                OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
              )
    ) AS n_falta_description_translated_recursos;

-- 2) Detalle a nivel de dataset: qué le falta a cada uno
--    (title_translated, description_translated, multilingual_tags)
WITH tag_count AS (
    SELECT pt.package_id, COUNT(*) AS n_tags
    FROM package_tag pt
    JOIN tag t ON t.id = pt.tag_id
    WHERE pt.state = 'active' AND t.vocabulary_id IS NULL
    GROUP BY pt.package_id
)
SELECT
    p.id                          AS package_id,
    p.name                        AS package_name,
    p.title                       AS title,
    LEFT(p.notes, 80)             AS notes_preview,
    COALESCE(tc.n_tags, 0)        AS n_tags_core,
    (title_ext.value IS NULL
        OR TRIM(title_ext.value) IN ('', '{}')
        OR title_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
    )                              AS falta_title_translated,
    (desc_ext.value IS NULL
        OR TRIM(desc_ext.value) IN ('', '{}')
        OR desc_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
    )                              AS falta_description_translated,
    (COALESCE(tc.n_tags, 0) > 0
        AND (
              tags_ext.value IS NULL
              OR TRIM(tags_ext.value) IN ('', '{}')
              OR tags_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*\[\s*\]\s*,?\s*)*\}\s*$'
            )
    )                              AS falta_multilingual_tags
FROM package p
LEFT JOIN tag_count tc
    ON tc.package_id = p.id
LEFT JOIN package_extra title_ext
    ON title_ext.package_id = p.id AND title_ext.key = 'title_translated'
LEFT JOIN package_extra desc_ext
    ON desc_ext.package_id = p.id AND desc_ext.key = 'description_translated'
LEFT JOIN package_extra tags_ext
    ON tags_ext.package_id = p.id AND tags_ext.key = 'multilingual_tags'
WHERE p.state = 'active' AND p.type = 'dataset'
  AND (
        (COALESCE(TRIM(p.title), '') <> '' AND (
            title_ext.value IS NULL
            OR TRIM(title_ext.value) IN ('', '{}')
            OR title_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
        ))
        OR
        (COALESCE(TRIM(p.notes), '') <> '' AND (
            desc_ext.value IS NULL
            OR TRIM(desc_ext.value) IN ('', '{}')
            OR desc_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
        ))
        OR
        (COALESCE(tc.n_tags, 0) > 0 AND (
            tags_ext.value IS NULL
            OR TRIM(tags_ext.value) IN ('', '{}')
            OR tags_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*\[\s*\]\s*,?\s*)*\}\s*$'
        ))
      )
ORDER BY p.name;

-- 3) Detalle a nivel de recurso: qué le falta a cada uno
--    (name_translated, description_translated)
SELECT
    p.id                           AS package_id,
    p.name                         AS package_name,
    r.id                           AS resource_id,
    r.name                         AS resource_name,
    LEFT(r.description, 80)        AS resource_description_preview,
    (COALESCE(TRIM(r.name), '') <> ''
        AND (
              (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) IS NULL
              OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END)) IN ('', '{}')
              OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'name_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
            )
    )                               AS falta_name_translated,
    (COALESCE(TRIM(r.description), '') <> ''
        AND (
              (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) IS NULL
              OR TRIM((CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END)) IN ('', '{}')
              OR (CASE WHEN r.extras ~ '^\s*\{.*\}\s*$' THEN r.extras::json ->> 'description_translated' END) ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
            )
    )                               AS falta_description_translated,
    r.extras                       AS extras_raw
FROM resource r
JOIN package p ON p.id = r.package_id
WHERE r.state = 'active'
  AND p.state = 'active' AND p.type = 'dataset'
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
      )
ORDER BY p.name, r.name;

-- 4) Candidatos al síntoma de package_search "num_resources/num_tags > 0
--    pero resources/tags/extras/groups vacíos": datasets con recursos y
--    tags reales en BD que no están internacionalizados en absoluto
--    (ver supuesto 6 de la cabecera).
WITH tag_count AS (
    SELECT pt.package_id, COUNT(*) AS n_tags
    FROM package_tag pt
    JOIN tag t ON t.id = pt.tag_id
    WHERE pt.state = 'active' AND t.vocabulary_id IS NULL
    GROUP BY pt.package_id
),
resource_count AS (
    SELECT r.package_id, COUNT(*) AS n_resources
    FROM resource r
    WHERE r.state = 'active'
    GROUP BY r.package_id
)
SELECT
    p.id                    AS package_id,
    p.name                  AS package_name,
    p.title                 AS title,
    rc.n_resources          AS n_resources_bd,
    tc.n_tags               AS n_tags_bd
FROM package p
JOIN resource_count rc ON rc.package_id = p.id
JOIN tag_count tc ON tc.package_id = p.id
WHERE p.state = 'active' AND p.type = 'dataset'
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = p.id
        AND pe.key = 'title_translated'
        AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
        AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
  )
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = p.id
        AND pe.key = 'description_translated'
        AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
        AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
  )
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = p.id
        AND pe.key = 'multilingual_tags'
        AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
        AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*\[\s*\]\s*,?\s*)*\}\s*$'
  )
ORDER BY rc.n_resources DESC, tc.n_tags DESC;
