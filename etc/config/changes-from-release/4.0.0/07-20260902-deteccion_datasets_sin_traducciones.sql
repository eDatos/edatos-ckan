-- =========================================================================
-- Detecta datasets que tienen title y/o notes (campos nativos de package)
-- pero carecen de title_translated y/o description_translated en
-- package_extra (asumido: campos de ckanext-fluent / edatosscheming).
--
-- SUPUESTOS A VERIFICAR ANTES DE USAR:
--   1. Las keys en package_extra se llaman exactamente
--      'title_translated' y 'description_translated'.
--      Si en tu esquema son otras (p.ej. 'notes_translated'), cambia
--      los literales en las cláusulas ON / WHERE de abajo.
--   2. "Carecer de" = no existe la fila extra, o existe pero el JSON
--      está vacío / es NULL / es '{}' / no tiene ningún valor no vacío
--      para ningún idioma. El chequeo de "JSON con todos los idiomas
--      vacíos" se hace con una comprobación de texto simple (LIKE),
--      no con un parseo JSON real -- revisa el resultado, puede haber
--      falsos negativos si el JSON tiene espacios/formato distinto.
--   3. Solo se consideran datasets activos (state = 'active') y
--      privados/públicos por igual. Ajusta el filtro state si quieres
--      limitarlo.
-- =========================================================================

-- 1) Vista rápida: solo conteo, para ver el tamaño del problema
SELECT
    (SELECT COUNT(*) FROM package p
        WHERE p.state = 'active'
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
        WHERE p.state = 'active'
          AND COALESCE(TRIM(p.notes), '') <> ''
          AND NOT EXISTS (
              SELECT 1 FROM package_extra pe
              WHERE pe.package_id = p.id
                AND pe.key = 'description_translated'
                AND COALESCE(TRIM(pe.value), '') NOT IN ('', '{}')
                AND pe.value !~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
          )
    ) AS n_falta_description_translated;

-- 2) Listado detallado: dataset, qué le falta, y el título/notes original
--    (para poder priorizar/inspeccionar caso a caso)
SELECT
    p.id                         AS package_id,
    p.name                       AS package_name,
    p.title                      AS title,
    LEFT(p.notes, 80)            AS notes_preview,
    (title_ext.value IS NULL
        OR TRIM(title_ext.value) IN ('', '{}')
        OR title_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
    )                            AS falta_title_translated,
    (desc_ext.value IS NULL
        OR TRIM(desc_ext.value) IN ('', '{}')
        OR desc_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
    )                            AS falta_description_translated,
    title_ext.value              AS title_translated_raw,
    desc_ext.value               AS description_translated_raw
FROM package p
LEFT JOIN package_extra title_ext
    ON title_ext.package_id = p.id
   AND title_ext.key = 'title_translated'
LEFT JOIN package_extra desc_ext
    ON desc_ext.package_id = p.id
   AND desc_ext.key = 'description_translated'
WHERE p.state = 'active'
  AND (
        -- tiene title pero le falta title_translated
        (
          COALESCE(TRIM(p.title), '') <> ''
          AND (
                title_ext.value IS NULL
                OR TRIM(title_ext.value) IN ('', '{}')
                OR title_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
              )
        )
        OR
        -- tiene notes pero le falta description_translated
        (
          COALESCE(TRIM(p.notes), '') <> ''
          AND (
                desc_ext.value IS NULL
                OR TRIM(desc_ext.value) IN ('', '{}')
                OR desc_ext.value ~ '^\s*\{\s*("[a-z]{2,3}"\s*:\s*""\s*,?\s*)*\}\s*$'
              )
        )
      )
ORDER BY p.name;