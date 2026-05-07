#!/bin/bash
# docker/ckan/docker-entrypoint.d/03_setup_showcase.sh
# Creación de tablas de ckanext-showcase si no existen

set -e

source /docker-entrypoint.d/00_logging_setup.sh 2>/dev/null || true

log_info "[03_setup_showcase] Verificando tablas de showcase..."

if [[ $CKAN__PLUGINS == *"edatosshowcase"* ]] || [[ $CKAN__PLUGINS == *"showcase"* ]]; then
    log_info "[03_setup_showcase] Plugin showcase encontrado en plugins"

    if echo "
from ckan.model.meta import engine
from ckanext.showcase.model import ShowcasePackageAssociation, ShowcaseAdmin
with engine.connect() as conn:
    if not engine.dialect.has_table(conn, 'showcase_package_association'):
        ShowcasePackageAssociation.__table__.create(bind=engine)
        print('[03_setup_showcase] Tabla showcase_package_association creada')
    else:
        print('[03_setup_showcase] Tabla showcase_package_association ya existe')
    if not engine.dialect.has_table(conn, 'showcase_admin'):
        ShowcaseAdmin.__table__.create(bind=engine)
        print('[03_setup_showcase] Tabla showcase_admin creada')
    else:
        print('[03_setup_showcase] Tabla showcase_admin ya existe')
" | ckan -c ${CKAN_INI} shell 2>&1 | tee -a ${ENTRYPOINT_LOG:-/dev/null}; then
        log_success "[03_setup_showcase] Tablas de showcase listas"
    else
        log_error "[03_setup_showcase] Error al crear las tablas de showcase"
    fi
else
    log_warn "[03_setup_showcase] Showcase no está habilitado en CKAN__PLUGINS"
fi

log_info "[03_setup_showcase] Configuración completada"
