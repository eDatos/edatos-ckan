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

import ckan.lib.helpers as h
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
            '0.0.0.dev' + datetime.now().strftime('%Y%m%d%H%M') + '+snapshot'
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


def _activity_list_for_anonymous(action_name, original_action, context, data_dict):
    """Returns no activity data for anonymous users, real data otherwise.

    Deliberately does NOT deny access (would raise NotAuthorized -> HTTP
    403). In the deployment environments this catalog runs in, any 403
    response gets intercepted by the reverse proxy and redirected to a
    generic branded error page, discarding whatever specific message the
    app tried to show. Returning an empty list keeps the response at 200,
    so the real activity_stream page renders normally (nav, tabs) with a
    flash banner in place of the actual entries.

    Still calls check_access explicitly: CKAN's action wrapper requires
    every action to consult its auth function (raises "did not call its
    auth function" otherwise) — this also preserves the real 403 for a
    genuinely private object (object-level visibility, not this
    feature-level gate), which stays correct/rare on a public open-data
    catalog.
    """
    toolkit.check_access(action_name, context, data_dict)
    if not context.get('user'):
        h.flash_error(
            toolkit._(u'You must log in to see the Activity Stream.'))
        return []
    return original_action(context, data_dict)


@toolkit.chained_action
@toolkit.side_effect_free
def package_activity_list(original_action, context, data_dict):
    return _activity_list_for_anonymous(
        'package_activity_list', original_action, context, data_dict)


@toolkit.chained_action
@toolkit.side_effect_free
def group_activity_list(original_action, context, data_dict):
    return _activity_list_for_anonymous(
        'group_activity_list', original_action, context, data_dict)


@toolkit.chained_action
@toolkit.side_effect_free
def organization_activity_list(original_action, context, data_dict):
    return _activity_list_for_anonymous(
        'organization_activity_list', original_action, context, data_dict)


@toolkit.chained_action
@toolkit.side_effect_free
def user_activity_list(original_action, context, data_dict):
    return _activity_list_for_anonymous(
        'user_activity_list', original_action, context, data_dict)
