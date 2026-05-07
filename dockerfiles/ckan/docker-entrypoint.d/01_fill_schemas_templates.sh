#!/bin/bash
# docker/ckan/docker-entrypoint.d/01_fill_schemas_templates.sh
# Genera los schemas finales a partir de los templates,
# sustituyendo FILL_REQUIRED_LANGUAGE por el valor de CKAN__LOCALE_DEFAULT.

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

TEMPLATES_DIR="/srv/app/src/ckanext-edatosscheming/ckanext/edatosscheming/schemas_templates"
SCHEMAS_DIR="/srv/app/src/ckanext-edatosscheming/ckanext/edatosscheming/schemas"

log_info "[01_fill_schemas] Iniciando generación de schemas desde templates..."

# Obtener el idioma por defecto de la variable de entorno
LOCALE_DEFAULT="${CKAN__LOCALE_DEFAULT:-es}"
log_info "[01_fill_schemas] CKAN__LOCALE_DEFAULT = '${LOCALE_DEFAULT}'"

# Crear directorio de schemas si no existe
mkdir -p "${SCHEMAS_DIR}"

# Procesar cada template JSON
TEMPLATE_COUNT=0
for template in "${TEMPLATES_DIR}"/*.json; do
    if [ ! -f "$template" ]; then
        log_warn "[01_fill_schemas] No se encontraron templates en ${TEMPLATES_DIR}"
        break
    fi

    filename=$(basename "$template")
    output="${SCHEMAS_DIR}/${filename}"

    log_info "[01_fill_schemas] Procesando template: ${filename}"

    # Sustituir FILL_REQUIRED_LANGUAGE por el valor de CKAN__LOCALE_DEFAULT
    sed "s/FILL_REQUIRED_LANGUAGE/${LOCALE_DEFAULT}/g" "$template" > "$output"

    TEMPLATE_COUNT=$((TEMPLATE_COUNT + 1))
    log_success "[01_fill_schemas] Schema generado: ${output}"
done

log_success "[01_fill_schemas] ${TEMPLATE_COUNT} schemas generados con required_language='${LOCALE_DEFAULT}'"
