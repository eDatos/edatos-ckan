-- NOTA:
-- Este script detecta, de forma generica (sin lista de ids hardcodeada),
-- todos los datasets cuyo campo "theme" en package_extra NO es un array
-- JSON valido, sino el string antiguo con las URIs concatenadas por comas.
-- Ese es el valor que, al serializarse en el RDF/DCAT, sale con las URIs
-- unidas por "%2C" y provoca el error E4005 ("El campo Temáticas (dcat:theme)
-- tiene un valor no válido") en el validador.
--
-- Un array JSON valido siempre empieza por '['; si el value no empieza por
-- '[' es que sigue siendo el string concatenado por comas.
--
-- Solo lectura: no modifica datos. Usar el resultado para generar el
-- siguiente script de correccion (mismo patron que 02/04/05 de esta carpeta).

-- 1) Listado detallado: dataset, package_id, id de package_extra y valor actual
SELECT
    p.name  AS dataset_slug,
    p.id    AS package_id,
    pe.id   AS extra_id,
    pe.value
FROM package_extra pe
JOIN package p ON p.id = pe.package_id
WHERE pe.key = 'theme'
  AND pe.value IS NOT NULL
  AND pe.value NOT LIKE '[%'
  AND p.state = 'active'
ORDER BY p.name;

-- 2) Recuento total de datasets afectados
SELECT count(*) AS total_theme_mal_formado
FROM package_extra pe
JOIN package p ON p.id = pe.package_id
WHERE pe.key = 'theme'
  AND pe.value IS NOT NULL
  AND pe.value NOT LIKE '[%'
  AND p.state = 'active';
