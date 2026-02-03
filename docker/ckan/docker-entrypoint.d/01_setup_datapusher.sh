#!/bin/bash
# docker/ckan/docker-entrypoint.d/01_setup_datapusher.sh
# Configuración de DataPusher

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info "[01_setup_datapusher] Iniciando configuración de DataPusher..."

if [[ $CKAN__PLUGINS == *"datapusher"* ]]; then
    log_info "[01_setup_datapusher] DataPusher encontrado en plugins"
    
    if [ -z "$CKAN__DATAPUSHER__API_TOKEN" ] ; then
        log_info "[01_setup_datapusher] Generando API token para DataPusher..."
        try_count=0
        max_tries=3
        
        while [ $try_count -lt $max_tries ]; do
            if ckan config-tool $CKAN_INI "ckan.datapusher.api_token=$(ckan -c $CKAN_INI user token add ckan_admin datapusher 2>&1 | tail -n 1 | tr -d '\t')" 2>&1 | tee -a $ENTRYPOINT_LOG; then
                log_success "[01_setup_datapusher] API token para DataPusher creado correctamente"
                break
            else
                try_count=$((try_count + 1))
                if [ $try_count -lt $max_tries ]; then
                    log_warn "[01_setup_datapusher] Intento $try_count falló, reintentando en 5 segundos..."
                    sleep 5
                else
                    log_error "[01_setup_datapusher] No se pudo crear el API token después de $max_tries intentos"
                fi
            fi
        done
    else
        log_info "[01_setup_datapusher] API token ya configurado"
    fi
else
    log_warn "[01_setup_datapusher] DataPusher no está habilitado en CKAN__PLUGINS"
fi

log_info "[01_setup_datapusher] Configuración completada"