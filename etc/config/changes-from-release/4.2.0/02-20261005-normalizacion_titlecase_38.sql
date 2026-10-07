-- =====================================================================
-- Ejecución: Este script de normalización se ha ejecutado en PRO ISTAC
--            y no debe ser ejecutado en otros entornos
--
-- Normalizacion a minusculas del texto intermedio para 38 etiquetas
-- revisadas manualmente de la lista de "mayusculas internas".
-- Regla aplicada: se mantiene mayuscula solo la primera letra de la
-- etiqueta; el resto pasa a minuscula, EXCEPTO:
--   - "Canarias" (nombre propio) se mantiene en mayuscula donde aparece
--   - Las siglas entre guiones se mantienen tal cual: -EMH-, -ESCRI-,
--     -FRONTUR-Canarias-, -IPRI-, -IPI-, -ICM-
--   - "Cifras" en "...Hipotecas. Cifras..." se mantiene en mayuscula
--     por ir despues de un punto (nueva frase)
-- Verificado: ninguno de estos 38 valores "nuevos" coincide con otra
-- etiqueta ya existente en el corpus, así que no hay riesgo de
-- duplicado dentro del mismo array (a diferencia del caso ganaderia).
--
-- 3 etiquetas de tu lista de 41 se excluyen por ser no-op:
--   - "Indicadores laborales": ya estaba bien formada, sin mayusculas
--     internas.
--   - "Justicia y Seguridad": tal como la escribiste no existe en los
--     datos; la etiqueta real es "Justicia y seguridad" (ya correcta).
--   - "Indices de valor unitario para el comercio exterior de
--     Canarias": su unica mayuscula interna es "Canarias", que se
--     preserva por ser nombre propio -> no hay nada que cambiar.
-- =====================================================================

-- 1) "Censo Agrario" -> "Censo agrario"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Censo Agrario' THEN 'Censo agrario' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Censo Agrario'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 2) "Censos de Población y Viviendas" -> "Censos de población y viviendas"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Censos de Población y Viviendas' THEN 'Censos de población y viviendas' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Censos de Población y Viviendas'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 3) "Encuesta Anual de Servicios" -> "Encuesta anual de servicios"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta Anual de Servicios' THEN 'Encuesta anual de servicios' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta Anual de Servicios'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 4) "Encuesta de Alojamiento en Establecimientos Hoteleros" -> "Encuesta de alojamiento en establecimientos hoteleros"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Alojamiento en Establecimientos Hoteleros' THEN 'Encuesta de alojamiento en establecimientos hoteleros' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Alojamiento en Establecimientos Hoteleros'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 5) "Encuesta de Alojamiento Turístico en Establecimientos Extrahoteleros" -> "Encuesta de alojamiento turístico en establecimientos extrahoteleros"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Alojamiento Turístico en Establecimientos Extrahoteleros' THEN 'Encuesta de alojamiento turístico en establecimientos extrahoteleros' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Alojamiento Turístico en Establecimientos Extrahoteleros'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 6) "Encuesta de Condiciones de Vida" -> "Encuesta de condiciones de vida"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Condiciones de Vida' THEN 'Encuesta de condiciones de vida' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Condiciones de Vida'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 7) "Encuesta de Morbilidad Hospitalaria -EMH-" -> "Encuesta de morbilidad hospitalaria -EMH-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Morbilidad Hospitalaria -EMH-' THEN 'Encuesta de morbilidad hospitalaria -EMH-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Morbilidad Hospitalaria -EMH-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 8) "Encuesta de Salud de Canarias" -> "Encuesta de salud de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Salud de Canarias' THEN 'Encuesta de salud de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Salud de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 9) "Encuesta de Salud e Ingresos de Canarias" -> "Encuesta de salud e ingresos de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Salud e Ingresos de Canarias' THEN 'Encuesta de salud e ingresos de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Salud e Ingresos de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 10) "Encuesta de Tecnologías de la Información y la Comunicación en las Empresas de Canarias" -> "Encuesta de tecnologías de la información y la comunicación en las empresas de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta de Tecnologías de la Información y la Comunicación en las Empresas de Canarias' THEN 'Encuesta de tecnologías de la información y la comunicación en las empresas de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta de Tecnologías de la Información y la Comunicación en las Empresas de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 11) "Encuesta Industrial de Empresas" -> "Encuesta industrial de empresas"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta Industrial de Empresas' THEN 'Encuesta industrial de empresas' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta Industrial de Empresas'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 12) "Encuesta sobre el Gasto Turístico" -> "Encuesta sobre el gasto turístico"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Encuesta sobre el Gasto Turístico' THEN 'Encuesta sobre el gasto turístico' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Encuesta sobre el Gasto Turístico'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 13) "Establecimientos Sanitarios con Régimen de Internado -ESCRI-" -> "Establecimientos sanitarios con régimen de internado -ESCRI-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Establecimientos Sanitarios con Régimen de Internado -ESCRI-' THEN 'Establecimientos sanitarios con régimen de internado -ESCRI-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Establecimientos Sanitarios con Régimen de Internado -ESCRI-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 14) "Estadística Agraria de Canarias" -> "Estadística agraria de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística Agraria de Canarias' THEN 'Estadística agraria de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística Agraria de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 15) "Estadística de Accidentes de Trabajo" -> "Estadística de accidentes de trabajo"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Accidentes de Trabajo' THEN 'Estadística de accidentes de trabajo' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Accidentes de Trabajo'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 16) "Estadística de Afiliación a la Seguridad Social" -> "Estadística de afiliación a la seguridad social"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Afiliación a la Seguridad Social' THEN 'Estadística de afiliación a la seguridad social' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Afiliación a la Seguridad Social'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 17) "Estadística de Bibliotecas" -> "Estadística de bibliotecas"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Bibliotecas' THEN 'Estadística de bibliotecas' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Bibliotecas'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 18) "Estadística de Comercio Exterior de Canarias" -> "Estadística de comercio exterior de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Comercio Exterior de Canarias' THEN 'Estadística de comercio exterior de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Comercio Exterior de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 19) "Estadística de Empresas Inscritas en la Seguridad Social" -> "Estadística de empresas inscritas en la seguridad social"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Empresas Inscritas en la Seguridad Social' THEN 'Estadística de empresas inscritas en la seguridad social' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Empresas Inscritas en la Seguridad Social'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 20) "Estadística de Hipotecas. Cifras en pequeñas áreas de Canarias" -> "Estadística de hipotecas. Cifras en pequeñas áreas de Canarias"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Hipotecas. Cifras en pequeñas áreas de Canarias' THEN 'Estadística de hipotecas. Cifras en pequeñas áreas de Canarias' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Hipotecas. Cifras en pequeñas áreas de Canarias'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 21) "Estadística del Turismo Español" -> "Estadística del turismo español"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística del Turismo Español' THEN 'Estadística del turismo español' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística del Turismo Español'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 22) "Estadística de Movimientos Turísticos en Fronteras de Canarias -FRONTUR-Canarias-" -> "Estadística de movimientos turísticos en fronteras de Canarias -FRONTUR-Canarias-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Movimientos Turísticos en Fronteras de Canarias -FRONTUR-Canarias-' THEN 'Estadística de movimientos turísticos en fronteras de Canarias -FRONTUR-Canarias-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Movimientos Turísticos en Fronteras de Canarias -FRONTUR-Canarias-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 23) "Estadística de Nacimientos" -> "Estadística de nacimientos"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Nacimientos' THEN 'Estadística de nacimientos' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Nacimientos'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 24) "Estadística de Variaciones Residenciales" -> "Estadística de variaciones residenciales"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística de Variaciones Residenciales' THEN 'Estadística de variaciones residenciales' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística de Variaciones Residenciales'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 25) "Estadística Inserción Laboral" -> "Estadística inserción laboral"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística Inserción Laboral' THEN 'Estadística inserción laboral' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística Inserción Laboral'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 26) "Estadística sobre Accidentes de Circulación" -> "Estadística sobre accidentes de circulación"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Estadística sobre Accidentes de Circulación' THEN 'Estadística sobre accidentes de circulación' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Estadística sobre Accidentes de Circulación'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 27) "Explotación Estadística del Padrón Municipal" -> "Explotación estadística del padrón municipal"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Explotación Estadística del Padrón Municipal' THEN 'Explotación estadística del padrón municipal' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Explotación Estadística del Padrón Municipal'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 28) "Formación Profesional" -> "Formación profesional"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Formación Profesional' THEN 'Formación profesional' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Formación Profesional'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 29) "Indicadores de Desarrollo Sostenible" -> "Indicadores de desarrollo sostenible"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Indicadores de Desarrollo Sostenible' THEN 'Indicadores de desarrollo sostenible' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Indicadores de Desarrollo Sostenible'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 30) "Indicadores Demográficos" -> "Indicadores demográficos"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Indicadores Demográficos' THEN 'Indicadores demográficos' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Indicadores Demográficos'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 31) "Índice de Precios al Consumo" -> "Índice de precios al consumo"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Índice de Precios al Consumo' THEN 'Índice de precios al consumo' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Índice de Precios al Consumo'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 32) "Índice de Precios Industriales -IPRI-" -> "Índice de precios industriales -IPRI-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Índice de Precios Industriales -IPRI-' THEN 'Índice de precios industriales -IPRI-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Índice de Precios Industriales -IPRI-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 33) "Índice de Producción Industrial -IPI-" -> "Índice de producción industrial -IPI-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Índice de Producción Industrial -IPI-' THEN 'Índice de producción industrial -IPI-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Índice de Producción Industrial -IPI-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 34) "Índices de Comercio al por Menor -ICM-" -> "Índices de comercio al por menor -ICM-"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Índices de Comercio al por Menor -ICM-' THEN 'Índices de comercio al por menor -ICM-' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Índices de Comercio al por Menor -ICM-'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 35) "Museos y Colecciones Museográficas" -> "Museos y colecciones museográficas"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Museos y Colecciones Museográficas' THEN 'Museos y colecciones museográficas' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Museos y Colecciones Museográficas'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 36) "Recopilación de Estadísticas de Deportes" -> "Recopilación de estadísticas de deportes"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Recopilación de Estadísticas de Deportes' THEN 'Recopilación de estadísticas de deportes' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Recopilación de Estadísticas de Deportes'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 37) "Recopilación de Estadísticas de Transporte Aéreo" -> "Recopilación de estadísticas de transporte aéreo"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Recopilación de Estadísticas de Transporte Aéreo' THEN 'Recopilación de estadísticas de transporte aéreo' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Recopilación de Estadísticas de Transporte Aéreo'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

-- 38) "Recopilación de Estadísticas sobre Seguridad y Delincuencia" -> "Recopilación de estadísticas sobre seguridad y delincuencia"
UPDATE package_extra
SET value = jsonb_set(
      value::jsonb, '{es}',
      (SELECT jsonb_agg(CASE WHEN elem = 'Recopilación de Estadísticas sobre Seguridad y Delincuencia' THEN 'Recopilación de estadísticas sobre seguridad y delincuencia' ELSE elem END ORDER BY ord)
       FROM jsonb_array_elements_text(value::jsonb #> '{es}') WITH ORDINALITY AS t(elem, ord))
    )::text
WHERE key = 'multilingual_tags'
  AND value::jsonb #> '{es}' ? 'Recopilación de Estadísticas sobre Seguridad y Delincuencia'
RETURNING id, package_id, value::jsonb #> '{es}' AS es_actualizado;

