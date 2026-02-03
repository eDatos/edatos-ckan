#!/bin/bash
# docker/ckan/docker-entrypoint.d/00_logging_setup.sh
# Script de inicialización de logging para todos los entrypoint scripts
# Escribe a stdout para que Docker capture los logs

set -e

# Funciones helper para logging (escriben a stdout)
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_warn() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [✓] $*"
}

export -f log_info log_warn log_error log_success

# Inicio del proceso
log_info "========================================"
log_info "Docker Entrypoint Scripts Initialization"
log_info "========================================"
log_info "CKAN_INI: ${CKAN_INI}"
log_info "CKAN_CONFIG: ${CKAN_CONFIG}"
log_info "CKAN__PLUGINS: ${CKAN__PLUGINS}"
log_info "========================================"