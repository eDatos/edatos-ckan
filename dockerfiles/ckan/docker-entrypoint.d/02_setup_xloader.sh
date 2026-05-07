#!/bin/bash
# docker/ckan/docker-entrypoint.d/02_setup_xloader.sh
# Configuración de XLoader

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info "[02_setup_xloader] Iniciando configuración de XLoader..."

if [[ $CKAN__PLUGINS == *"xloader"* ]]; then
    log_info "[02_setup_xloader] XLoader encontrado en plugins"
    
    if [ -z "$CKAN__XLOADER__API_TOKEN" ] ; then
        log_info "[02_setup_xloader] Generando API token para XLoader..."
        try_count=0
        max_tries=3
        
        while [ $try_count -lt $max_tries ]; do
            if ckan config-tool $CKAN_INI "ckanext.xloader.api_token=$(ckan -c $CKAN_INI user token add ckan_admin xloader 2>&1 | tail -n 1 | tr -d '\t')" 2>&1 | tee -a $ENTRYPOINT_LOG; then
                log_success "[02_setup_xloader] API token para XLoader creado correctamente"
                break
            else
                try_count=$((try_count + 1))
                if [ $try_count -lt $max_tries ]; then
                    log_warn "[02_setup_xloader] Intento $try_count falló, reintentando en 5 segundos..."
                    sleep 5
                else
                    log_error "[02_setup_xloader] No se pudo crear el API token después de $max_tries intentos"
                fi
            fi
        done
    else
        log_info "[02_setup_xloader] API token ya configurado"
    fi
else
    log_warn "[02_setup_xloader] XLoader no está habilitado en CKAN__PLUGINS"
fi

log_info "[02_setup_xloader] Configuración completada"