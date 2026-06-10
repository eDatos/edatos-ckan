
BEGIN;

-- Eliminar SOLO los multilingual_tags vacíos o inexistentes (no tocar los que ya tienen valor real)
DELETE FROM package_extra
WHERE key = 'multilingual_tags'
  AND (value IS NULL OR value = '' OR value = '{}')
  AND package_id IN (
      SELECT id FROM package WHERE state = 'active' AND type = 'dataset'
  );

-- Insertar multilingual_tags para los datasets active que:
--   1. No tienen ya un multilingual_tags con valor real
--   2. Tienen al menos un tag activo
INSERT INTO package_extra (id, package_id, key, value, state)
SELECT
    (md5(random()::text || clock_timestamp()::text))::uuid::text,
    pt.package_id,
    'multilingual_tags',
    json_build_object('es', json_agg(t.name ORDER BY t.name))::text,
    'active'
FROM package_tag pt
JOIN tag t ON t.id = pt.tag_id
JOIN package p ON p.id = pt.package_id
WHERE pt.state = 'active'
  AND t.vocabulary_id IS NULL
  AND p.state = 'active'
  AND p.type = 'dataset'
  AND NOT EXISTS (
      SELECT 1 FROM package_extra pe
      WHERE pe.package_id = pt.package_id
        AND pe.key = 'multilingual_tags'
        AND pe.value IS NOT NULL
        AND pe.value != ''
        AND pe.value != '{}'
  )
GROUP BY pt.package_id;

COMMIT;