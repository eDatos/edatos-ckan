-- NOTA:
-- Este script detecta que conjuntos de datos tienen mas de una tematica
-- (dcat:theme) asignada, independientemente de si el campo "theme" en
-- package_extra ya esta corregido como array JSON valido o si todavia
-- esta en el formato antiguo (string concatenado por comas).
--
-- Solo lectura: no modifica datos.

WITH theme_data AS (
    SELECT
        p.name  AS dataset_slug,
        p.id    AS package_id,
        pe.id   AS extra_id,
        pe.value,
        CASE
            WHEN pe.value LIKE '[%' THEN jsonb_array_length(pe.value::jsonb)
            ELSE array_length(string_to_array(pe.value, ','), 1)
        END AS theme_count
    FROM package_extra pe
    JOIN package p ON p.id = pe.package_id
    WHERE pe.key = 'theme'
      AND pe.value IS NOT NULL
      AND p.state = 'active'
)

-- 1) Listado detallado: dataset, package_id, id de package_extra, valor y numero de tematicas
SELECT dataset_slug, package_id, extra_id, theme_count, value
FROM theme_data
WHERE theme_count > 1
ORDER BY theme_count DESC, dataset_slug;

-- 2) Recuento total de datasets con mas de una tematica
-- (consulta independiente, con su propio CTE)
WITH theme_data AS (
    SELECT
        pe.id AS extra_id,
        CASE
            WHEN pe.value LIKE '[%' THEN jsonb_array_length(pe.value::jsonb)
            ELSE array_length(string_to_array(pe.value, ','), 1)
        END AS theme_count
    FROM package_extra pe
    JOIN package p ON p.id = pe.package_id
    WHERE pe.key = 'theme'
      AND pe.value IS NOT NULL
      AND p.state = 'active'
)
SELECT count(*) AS total_datasets_multiples_tematicas
FROM theme_data
WHERE theme_count > 1;
