#!/bin/bash
# docker/ckan/docker-entrypoint.d/05_setup_dcat_endpoint.sh
# Configura la ruta del endpoint de DCAT en el ini de CKAN (ruta específica para el cliente)

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

CKAN_INI="${CKAN_INI:-/srv/app/ckan.ini}"
_DCAT_DEFAULT="/dcat/catalog.{_format}"
DCAT_ENDPOINT_VALUE="${CKANEXT__DCAT__CATALOG_ENDPOINT:-${_DCAT_DEFAULT}}"
DCAT_ENDPOINT="ckanext.dcat.catalog_endpoint = ${DCAT_ENDPOINT_VALUE}"

log_info "[05_setup_dcat_endpoint] Verificando configuración del endpoint DCAT..."

if grep -qF "ckanext.dcat.catalog_endpoint" "${CKAN_INI}"; then
    sed "s|^ckanext.dcat.catalog_endpoint =.*|${DCAT_ENDPOINT}|" "${CKAN_INI}" > /tmp/ckan_ini_tmp \
        && cat /tmp/ckan_ini_tmp > "${CKAN_INI}" \
        && rm -f /tmp/ckan_ini_tmp
    log_success "[05_setup_dcat_endpoint] Endpoint DCAT actualizado en ${CKAN_INI}"
else
    sed "/^\[app:main\]/a\\${DCAT_ENDPOINT}" "${CKAN_INI}" > /tmp/ckan_ini_tmp \
        && cat /tmp/ckan_ini_tmp > "${CKAN_INI}" \
        && rm -f /tmp/ckan_ini_tmp
    log_success "[05_setup_dcat_endpoint] Endpoint DCAT añadido a ${CKAN_INI}"
fi

log_info "[05_setup_dcat_endpoint] Configuración completada"
