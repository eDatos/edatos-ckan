#!/bin/bash
# docker/ckan/docker-entrypoint.d/04_debug_mode.sh
# Activa modo DEBUG si la variable DEBUG_MODE está establecida

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info "[04_debug_mode] Comprobando modo DEBUG..."

if [[ "${DEBUG_MODE}" == "true" ]] || [[ "${CKAN_DEBUG}" == "true" ]]; then
    log_info "[04_debug_mode] Activando modo DEBUG..."
    
    # Cambiar debug de false a true en ckan.ini
    if sed -i 's/^debug=false/debug=true/' /srv/app/ckan.ini 2>&1; then
        log_success "[04_debug_mode] debug=true configurado"
    else
        log_warn "[04_debug_mode] No se pudo actualizar debug en ckan.ini"
    fi
    
    # Cambiar nivel de logger ckanext a DEBUG
    if sed -i '/^\[logger_ckanext\]/,/^\[/ s/level = Info/level = DEBUG/' /srv/app/ckan.ini 2>&1; then
        log_success "[04_debug_mode] Logger ckanext configurado a DEBUG"
    else
        log_warn "[04_debug_mode] No se pudo actualizar logger ckanext"
    fi
    
    log_success "[04_debug_mode] Modo DEBUG activado"
else
    log_info "[04_debug_mode] Modo DEBUG deshabilitado (DEBUG_MODE=${DEBUG_MODE}, CKAN_DEBUG=${CKAN_DEBUG})"
fi

log_info "[04_debug_mode] Configuración completada"
