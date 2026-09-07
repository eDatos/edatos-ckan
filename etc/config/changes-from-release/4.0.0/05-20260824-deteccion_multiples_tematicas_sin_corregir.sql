-- NOTA:
-- Este script detecta los conjuntos de datos que tienen mas de una tematica
-- (dcat:theme) Y que ademas siguen SIN corregir, es decir, cuyo campo
-- "theme" en package_extra todavia es el string antiguo concatenado por
-- comas (no un array JSON valido). Es la interseccion de los criterios de
-- 06-20260824-deteccion_tematicas_mal_formadas.sql (mal formado) y
-- 07-20260824-deteccion_datasets_multiples_tematicas.sql (mas de una
-- tematica).
--
-- Un array JSON valido siempre empieza por '['; si el value no empieza por
-- '[' es que sigue siendo el string concatenado por comas.
--
-- Solo lectura: no modifica datos. Usar el resultado para generar el
-- siguiente script de correccion (mismo patron que 02/04/05 de esta carpeta).

WITH theme_data AS (
    SELECT
        p.name  AS dataset_slug,
        p.id    AS package_id,
        pe.id   AS extra_id,
        pe.value,
        array_length(string_to_array(pe.value, ','), 1) AS theme_count
    FROM package_extra pe
    JOIN package p ON p.id = pe.package_id
    WHERE pe.key = 'theme'
      AND pe.value IS NOT NULL
      AND pe.value NOT LIKE '[%'
      AND p.state = 'active'
)

-- 1) Listado detallado
SELECT dataset_slug, package_id, extra_id, theme_count, value
FROM theme_data
WHERE theme_count > 1
ORDER BY theme_count DESC, dataset_slug;

-- 2) Recuento total (consulta independiente, con su propio CTE)
WITH theme_data AS (
    SELECT
        pe.id AS extra_id,
        array_length(string_to_array(pe.value, ','), 1) AS theme_count
    FROM package_extra pe
    JOIN package p ON p.id = pe.package_id
    WHERE pe.key = 'theme'
      AND pe.value IS NOT NULL
      AND pe.value NOT LIKE '[%'
      AND p.state = 'active'
)
SELECT count(*) AS total_multiples_tematicas_sin_corregir
FROM theme_data
WHERE theme_count > 1;
