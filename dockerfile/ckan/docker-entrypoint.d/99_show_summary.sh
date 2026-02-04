#!/bin/bash
# docker/ckan/docker-entrypoint.d/99_show_summary.sh
# Muestra un resumen de la ejecución de los scripts de entrypoint
# Se ejecuta ÚLTIMO (por el 99_)

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info ""
log_info "========================================"
log_info "Docker Entrypoint Execution Summary"
log_info "========================================"

# Mostrar variables importantes
log_info "Environment Variables:"
log_info "  CKAN_SITE_URL: ${CKAN_SITE_URL}"
log_info "  CKAN_PLUGINS: ${CKAN__PLUGINS}"
log_info "  DEBUG_MODE: ${DEBUG_MODE}"
log_info "  CKAN_CONFIG: ${CKAN_CONFIG}"
log_info ""

# Verificar que ckan.ini existe y está actualizado
if [ -f "${CKAN_CONFIG}/ckan.ini" ]; then
    log_success "ckan.ini existe en: ${CKAN_CONFIG}/ckan.ini"
    log_info ""
    log_info "Configuración CKAN en ckan.ini:"
    log_info "  site_url: $(grep -E '^ckan.site_url' ${CKAN_CONFIG}/ckan.ini | cut -d= -f2 | tr -d ' ' || echo 'NOT SET')"
    log_info "  locale_default: $(grep -E '^ckan.locale_default' ${CKAN_CONFIG}/ckan.ini | cut -d= -f2 | tr -d ' ' || echo 'NOT SET')"
    log_info "  locale_order: $(grep -E '^ckan.locale_order' ${CKAN_CONFIG}/ckan.ini | cut -d= -f2 | tr -d ' ' || echo 'NOT SET')"
    log_info "  plugins: $(grep -E '^ckan.plugins' ${CKAN_CONFIG}/ckan.ini | cut -d= -f2 | tr -d ' ' || echo 'NOT SET')"
else
    log_error "ckan.ini NO ENCONTRADO en ${CKAN_CONFIG}/ckan.ini"
fi

log_info ""
log_info "Script execution log file: ${ENTRYPOINT_LOG}"
log_info ""
log_info "========================================"
log_info "Startup initialization complete"
log_info "========================================"
log_info ""