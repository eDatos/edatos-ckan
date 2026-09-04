-- NOTA:
-- Este script detecta conjuntos de datos con mas de una tematica (dcat:theme)
-- unidas por CUALQUIER estilo de separador, no solo el string plano sin
-- comillas que detectan 06/08. Cubre, entre otras, estas variantes:
--
--   , "http://      (coma + espacio + comilla doble)
--   ","http://      (comilla doble + coma + comilla doble, sin espacio)
--   ,http://        (coma a secas, sin comillas)
--   ', 'http://     (comilla simple + coma + espacio + comilla simple)
--   ','http://      (comilla simple + coma + comilla simple, sin espacio)
--
-- Esto incluye casos que 06-20260824-deteccion_tematicas_mal_formadas.sql
-- NO detecta porque su criterio (value NOT LIKE '[%') asume que cualquier
-- valor que empiece por '[' ya es un array JSON valido. Un value tipo
-- repr de lista Python con comillas simples (p.ej. ['http://a', 'http://b'])
-- tambien empieza por '[' pero NO es JSON valido, y este script si lo
-- detecta.
--
-- Solo lectura: no modifica datos.

-- 1) Listado detallado
SELECT
    p.name  AS dataset_slug,
    p.id    AS package_id,
    pe.id   AS extra_id,
    pe.value,
    (
        SELECT count(*)
        FROM regexp_matches(pe.value, $re$['"]?,\s*['"]?https?://$re$, 'g')
    ) + 1 AS theme_count_aprox
FROM package_extra pe
JOIN package p ON p.id = pe.package_id
WHERE pe.key = 'theme'
  AND pe.value IS NOT NULL
  AND pe.value ~ $re$['"]?,\s*['"]?https?://$re$
  AND p.state = 'active'
ORDER BY dataset_slug;

-- 2) Recuento total (consulta independiente)
SELECT count(*) AS total_datasets_multiples_tematicas_cualquier_separador
FROM package_extra pe
JOIN package p ON p.id = pe.package_id
WHERE pe.key = 'theme'
  AND pe.value IS NOT NULL
  AND pe.value ~ $re$['"]?,\s*['"]?https?://$re$
  AND p.state = 'active';
