#!/bin/bash
# docker/ckan/docker-entrypoint.d/06_build_js_translations.sh
# Genera el catálogo de traducciones de JavaScript (/api/i18n/<lang>). CKAN no lo crea solo:
# sin él, las cadenas de los módulos JS (p. ej. "Show more") salen en inglés.

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

CKAN_INI="${CKAN_INI:-/srv/app/ckan.ini}"

log_info "[06_build_js_translations] Generando traducciones de JavaScript..."

if ckan -c "${CKAN_INI}" translation js >/tmp/build_js_translations.log 2>&1; then
    log_success "[06_build_js_translations] Traducciones de JavaScript generadas"
else
    log_warn "[06_build_js_translations] No se pudieron generar (ver /tmp/build_js_translations.log)"
fi
