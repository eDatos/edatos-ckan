#!/bin/bash
# docker/ckan/docker-entrypoint.d/03_load_env_vars.sh
# Carga variables de entorno desde .env a ckan.ini

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info "[03_load_env_vars] Iniciando carga de variables de entorno..."

# Asegurar que CKAN_CONFIG está definido
CKAN_CONFIG="${CKAN_CONFIG:-/srv/app}"
CKAN_INI="${CKAN_CONFIG}/ckan.ini"
log_info "[03_load_env_vars] Usando ruta ckan.ini: ${CKAN_INI}"

if [ -f /srv/app/docker/bin/load_env_to_ckanini.py ]; then
    log_info "[03_load_env_vars] Ejecutando script de carga de variables..."
    if python3 /srv/app/docker/bin/load_env_to_ckanini.py "${CKAN_INI}" 2>&1 | tee -a $ENTRYPOINT_LOG; then
        log_success "[03_load_env_vars] Variables de entorno cargadas correctamente"
    else
        log_error "[03_load_env_vars] Error al cargar variables de entorno"
        exit 1
    fi
else
    log_warn "[03_load_env_vars] Script load_env_to_ckanini.py no encontrado en /srv/app/docker/bin/"
    log_info "[03_load_env_vars] Ruta esperada: /srv/app/docker/bin/load_env_to_ckanini.py"
fi

log_info "[03_load_env_vars] Carga de variables completada"