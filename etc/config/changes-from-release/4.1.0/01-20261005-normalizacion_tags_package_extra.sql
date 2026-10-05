-- =====================================================================
-- Normalización de etiquetas (es) en package_extra.value ->> 'es'
-- Generado a partir de package_extra_202609221336usuarioAPIkey.csv
-- Supuesto: package_extra.value es TEXT que contiene un JSON válido
--           con forma {"en": [...], "es": [...], "ca": [...]}
--           Verificar con: SELECT pg_typeof(value) FROM package_extra LIMIT 1;
--           Si el resultado es "jsonb" en vuestra BD real, quitar los
--           ::text finales y trabajar directo en jsonb (ver nota al final).
-- =====================================================================


-- =====================================================================
-- SECCIÓN 0. Verificación previa (solo lectura, no modifica nada)
-- =====================================================================

-- 0.1 Confirmar el tipo de columna
SELECT pg_typeof(value) FROM package_extra LIMIT 1;

-- 0.2 Confirmar cuántas filas tocará cada fix (ejecutar antes de cada UPDATE
--     de la sección 2 y 3 para comparar con el RETURNING posterior)


-- =====================================================================
-- SECCIÓN 1. Anomalía 'load_manual' (fuera de alcance de esta normalización)
-- =====================================================================
-- 'load_manual' aparece en los arrays es/en/ca de package_extra y no
-- parece una etiqueta temática real sino un artefacto de carga.
-- Se lista aquí para que se decida manualmente qué hacer (no se modifica).

SELECT package_id, key,
       value::jsonb #> '{es}' AS es,
       value::jsonb #> '{en}' AS en,
       value::jsonb #> '{ca}' AS ca
FROM package_extra
WHERE key = 'multilingual_tags'
  AND (value::jsonb #> '{es}' ? 'load_manual'
    OR value::jsonb #> '{en}' ? 'load_manual'
    OR value::jsonb #> '{ca}' ? 'load_manual');

-- 1.2) Hallazgo adicional detectado al validar este script: al menos un
--      paquete (f6c8c3ad-0426-4c7e-8fb5-93405e5ee981) tiene 'load_manual'
--      REPETIDO DOS VECES dentro del propio array 'es', ya en el dato
--      original (no lo provoca ninguna corrección de este script).
--      Esta consulta detecta cualquier array 'es' con elementos repetidos
--      (case-sensitive), para revisar si hay más casos así:
SELECT package_id, value::jsonb #> '{es}' AS es
FROM package_extra
WHERE key = 'multilingual_tags'
  AND jsonb_array_length(value::jsonb #> '{es}') <>
      (SELECT count(DISTINCT x) FROM jsonb_array_elements_text(value::jsonb #> '{es}') x);


-- =====================================================================
-- SECCIÓN 2. Duplicados por acento/mayúscula -> forma correcta y acentuada
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1) "Cartografia" -> "Cartografía"
-- ---------------------------------------------------------------------
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb,
      '{es}',
      (
        SELECT jsonb_agg(
                 CASE WHEN elem = 'Cartografia' THEN 'Cartografía' ELSE elem END
                 ORDER BY ord
               )
        FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord)
      )
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Cartografia'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- ---------------------------------------------------------------------
-- 2.2) "Poblacion" -> "Población"
-- ---------------------------------------------------------------------
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb,
      '{es}',
      (
        SELECT jsonb_agg(
                 CASE WHEN elem = 'Poblacion' THEN 'Población' ELSE elem END
                 ORDER BY ord
               )
        FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord)
      )
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Poblacion'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- ---------------------------------------------------------------------
-- 2.3) "hosteleria y turismo" -> "Hostelería y turismo"
-- ---------------------------------------------------------------------
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb,
      '{es}',
      (
        SELECT jsonb_agg(
                 CASE WHEN elem = 'hosteleria y turismo' THEN 'Hostelería y turismo' ELSE elem END
                 ORDER BY ord
               )
        FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord)
      )
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'hosteleria y turismo'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- ---------------------------------------------------------------------
-- 2.4a) "ganadería" -> "Ganadería"  (paquetes donde SOLO existe la variante
--        en minúscula; no hay conflicto con la forma correcta)
-- ---------------------------------------------------------------------
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb,
      '{es}',
      (
        SELECT jsonb_agg(
                 CASE WHEN elem = 'ganadería' THEN 'Ganadería' ELSE elem END
                 ORDER BY ord
               )
        FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord)
      )
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'ganadería'
  AND NOT (value::jsonb #> '{es}' ? 'Ganadería')
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- ---------------------------------------------------------------------
-- 2.4b) Elimina "ganadería" en los paquetes donde YA coexiste con
--        "Ganadería" (si no se hace esto, 2.4a habría dejado
--        ["Ganadería","Ganadería"] duplicada dentro del mismo array).
--        Hay 6 paquetes en este caso.
-- ---------------------------------------------------------------------
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb,
      '{es}',
      (
        SELECT jsonb_agg(elem ORDER BY ord)
        FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord)
        WHERE elem <> 'ganadería'
      )
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'ganadería'
  AND value::jsonb #> '{es}' ? 'Ganadería'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;


-- =====================================================================
-- SECCIÓN 3. Etiquetas totalmente en minúscula -> solo 1ª letra en mayúscula
--            (sin duplicado asociado; el resto de la etiqueta ya está en
--            minúsculas y no tiene mayúsculas internas)
-- =====================================================================

-- 3.1) "consumo e inversión" -> "Consumo e inversión"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'consumo e inversión' THEN 'Consumo e inversión' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'consumo e inversión'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.2) "deporte y ocio" -> "Deporte y ocio"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'deporte y ocio' THEN 'Deporte y ocio' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'deporte y ocio'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.3) "energía y agua" -> "Energía y agua"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'energía y agua' THEN 'Energía y agua' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'energía y agua'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.4) "entidades locales" -> "Entidades locales"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'entidades locales' THEN 'Entidades locales' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'entidades locales'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.5) "monetarios y seguros" -> "Monetarios y seguros"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'monetarios y seguros' THEN 'Monetarios y seguros' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'monetarios y seguros'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.6) "pesca y caza" -> "Pesca y caza"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'pesca y caza' THEN 'Pesca y caza' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'pesca y caza'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3.7) "restauración y otros" -> "Restauración y otros"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'restauración y otros' THEN 'Restauración y otros' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'restauración y otros'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;


-- =====================================================================
-- SECCIÓN 4. Verificación posterior (ejecutar tras 2.1-2.4b y 3.1-3.7)
--            Debe devolver 0 filas en todos los casos.
-- =====================================================================
SELECT 'Cartografia'            AS variante_deberia_no_existir, count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Cartografia'
UNION ALL SELECT 'Poblacion',              count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Poblacion'
UNION ALL SELECT 'hosteleria y turismo',   count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'hosteleria y turismo'
UNION ALL SELECT 'ganadería',              count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'ganadería'
UNION ALL SELECT 'consumo e inversión',    count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'consumo e inversión'
UNION ALL SELECT 'deporte y ocio',         count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'deporte y ocio'
UNION ALL SELECT 'energía y agua',         count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'energía y agua'
UNION ALL SELECT 'entidades locales',      count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'entidades locales'
UNION ALL SELECT 'monetarios y seguros',   count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'monetarios y seguros'
UNION ALL SELECT 'pesca y caza',           count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'pesca y caza'
UNION ALL SELECT 'restauración y otros',   count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'restauración y otros';

-- Confirmar que las formas correctas están presentes con el total esperado
-- (Cartografía: 8856+4004=12860, Población: 858+4004=4862,
--  Hostelería y turismo: 414+2=416, Ganadería: 6+96=102)
SELECT 'Cartografía' AS forma_correcta, count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Cartografía'
UNION ALL SELECT 'Población',              count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Población'
UNION ALL SELECT 'Hostelería y turismo',   count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Hostelería y turismo'
UNION ALL SELECT 'Ganadería',              count(*) FROM package_extra WHERE key='multilingual_tags' AND value::jsonb #> '{es}' ? 'Ganadería';


-- =====================================================================
-- SECCIÓN 5. Etiquetas 'es' con mayúsculas internas (más allá de la
--            primera letra) -> SOLO LECTURA, para revisión manual.
--            No se auto-corrigen: pueden ser siglas (ECOSOC, IPRI...),
--            nombres propios (Canarias) o nombres oficiales de encuestas
--            en Title Case, y aplicar "solo 1ª palabra en mayúscula" a
--            ciegas los destrozaría.
-- =====================================================================
WITH es_unnest AS (
    SELECT package_id, jsonb_array_elements_text(value::jsonb #> '{es}') AS tag
    FROM package_extra
    WHERE key = 'multilingual_tags'
)
SELECT tag,
       count(DISTINCT package_id) AS num_datasets
FROM es_unnest
WHERE tag <> 'load_manual'
  AND substring(tag from 2) ~ '[A-ZÁÉÍÓÚÜÑ]'
GROUP BY tag
ORDER BY tag;
