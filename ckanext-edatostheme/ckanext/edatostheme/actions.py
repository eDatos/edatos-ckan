# -*- coding: utf-8 -*-
"""
Overrides de acciones de la API CKAN para las extensiones ckan-istac.

Actualmente expone:
  status_show  ->  añade 'CKAN_EDATOS_VERSION' a la respuesta estandar.
"""
import os
import logging
from datetime import datetime

try:
    from importlib.metadata import version as _dist_version, PackageNotFoundError
except ImportError:                        # Python < 3.8 (compatibilidad)
    from importlib_metadata import version as _dist_version, PackageNotFoundError  # type: ignore[no-redef]

import ckan.plugins.toolkit as toolkit

log = logging.getLogger(__name__)

# Distribucion canonica de la que se leen los metadatos instalados.
# Debe coincidir con el campo 'name' de su setup.py.
_CANONICAL_DIST = 'ckanext-edatostheme'


def get_CKAN_EDATOS_VERSION():
    """
    Devuelve la version unificada del proyecto ckan-istac.

    La fuente es importlib.metadata, que lee los metadatos generados
    en tiempo de instalacion (pip install -e).  Su valor es identico
    al que muestra 'pip show ckanext-edatostheme'.

    Fallback: variable de entorno CKAN_EDATOS_VERSION si el paquete no esta
    instalado (ejecucion fuera del contenedor); si tampoco esta definida, se
    genera un snapshot con fecha/hora (mismo formato que el fallback local
    de cada setup.py) para dejar claro que no es una version de release.
    """
    try:
        return _dist_version(_CANONICAL_DIST)
    except PackageNotFoundError:
        log.warning(
            'No se encontraron metadatos de %s; '
            'usando CKAN_EDATOS_VERSION (o snapshot) como fallback.',
            _CANONICAL_DIST,
        )
        return os.environ.get('CKAN_EDATOS_VERSION') or (
            datetime.now().strftime('%d-%m-%Y-%H%M') + '-snapshot'
        )


@toolkit.chained_action
@toolkit.side_effect_free
def status_show(original_action, context, data_dict):
    """
    Extiende status_show con la version unificada del proyecto.

    Conserva 'ckan_version' (version del core) e incorpora el campo
    nuevo 'CKAN_EDATOS_VERSION' con el formato PEP 440 compuesto:
      <tag_gitlab>+ckan.<ckan_core_major.minor>
    Ejemplo: "10.0.0+ckan.2.11"
    """
    result = original_action(context, data_dict)
    result['CKAN_EDATOS_VERSION'] = get_CKAN_EDATOS_VERSION()
    return result
