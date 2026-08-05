
# -*- coding: UTF-8 -*-
import codecs
import json
import logging
import os
import time
import threading

import ckan.lib.base as base
import ckan.lib.helpers as h
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import requests
import ckanext.scheming.helpers as sh

from urllib.parse import urlparse

from bs4 import BeautifulSoup
from ckan.common import _, request, c
from collections import OrderedDict
from ckan.model import Package
from ckan.lib.plugins import DefaultTranslation
from ckantoolkit import config, h, _, request, abort
from flask import Blueprint, current_app
from flask import render_template_string

import logging
log = logging.getLogger(__name__)

_REQUESTS_TIMEOUT = 10      # segundos — timeout para todas las llamadas requests.get


abort = base.abort
dirname = os.path.dirname(__file__)
CONFIG_FILE_PATH = os.path.join(dirname, '../etc/config.json')
FOOTER_PATH = os.path.join(dirname, '../templates/footer.html')
FAVICON_PATH = os.path.join(dirname, '../public/favicon.ico')
SCRIPT_PATH = os.path.join(dirname, '../assets/js/i18n.js')
BURGER_BUTTON_PATH = os.path.join(
    dirname, '../code_templates/burger_button.html')
SCRIPT_TEMPLATE = os.path.join(dirname, '../code_templates/i18n.js')

HERE = os.path.abspath(os.path.dirname(__file__))
I18N_DIR = os.path.join(HERE, "../i18n")
APP_ID_FOR_ANALYTICS = 'ckan-catalog'

# ---------------------------------------------------------------------------
# Caché en memoria para helpers costosos (group, freq_tags).
# TTL por defecto: 60s para grupos, 120s para tags frecuentes.
# ---------------------------------------------------------------------------
_GROUP_CACHE = {}           # {group_id: (timestamp, dict)}
_GROUP_CACHE_LOCK = threading.Lock()
_FREQ_TAGS_CACHE = {}       # {lang: (timestamp, list)}
_FREQ_TAGS_CACHE_LOCK = threading.Lock()
def edatos_pager(page, **kwargs):
    """Paginación con ventana deslizante de 5 páginas y ellipsis.

    Comportamiento (ejemplo con 117 páginas):
      pág   1 →       [1*][2][3][4][5] … [117] [»]   (sin «)
      pág   4 → [«] [1][2][3][4*][5][6] … [117] [»]
      pág   5 → [«] [1]…[3][4][5*][6][7] … [117] [»]
      pág   7 → [«] [1]…[5][6][7*][8][9] … [117] [»]
      pág 114 → [«] [1]…[112][113][114*][115][116][117] [»]
      pág 116 → [«] [1]…[113][114][115][116*][117] [»]
      pág 117 → [«] [1]…[113][114][115][116][117*]      (sin »)
    """
    from markupsafe import Markup
    from ckan.lib.helpers import pager_url

    if not page.last_page or page.last_page <= 1:
        return Markup('')

    first   = page.first_page   # siempre 1
    last    = page.last_page
    current = page.page

    WINDOW = 5       # tamaño del bloque deslizante
    HALF   = WINDOW // 2  # páginas a cada lado (= 2)

    # Generador de URLs: usa el propio de la instancia o el helper de CKAN
    url_gen = getattr(page, '_url_generator', None) or pager_url

    def make_url(p):
        params = dict(getattr(page, 'kwargs', {}))
        params.update(kwargs)
        params['page'] = p
        return url_gen(**params)

    # Ventana deslizante centrada en current
    win_start = max(first, current - HALF)
    win_end   = min(last,  current + HALF)

    # Si la ventana quedó reducida por un extremo, compensar por el otro
    if win_end - win_start < WINDOW - 1:
        if win_start == first:
            win_end = min(last, win_start + WINDOW - 1)
        else:
            win_start = max(first, win_end - WINDOW + 1)

    window_pages = set(range(win_start, win_end + 1))
    visible = sorted({first, last} | window_pages)

    li_items = []

    # Botón anterior (chevron izquierdo)
    if page.previous_page:
        li_items.append(
            '<li class="page-item">'
            '<a class="page-link" href="{url}">'
            '<i class="fa-thin fa-chevrons-left"></i>'
            '</a></li>'.format(url=make_url(page.previous_page))
        )
    else:
        li_items.append(
            '<li class="page-item disabled">'
            '<a class="page-link">'
            '<i class="fa-thin fa-chevrons-left"></i>'
            '</a></li>'
        )

    # Páginas con ellipsis entre huecos
    prev_num = None
    for p in visible:
        if prev_num is not None and p - prev_num > 1:
            li_items.append(
                '<li class="page-item page-ellipsis">'
                '<span class="page-link">&hellip;</span>'
                '</li>'
            )
        if p == current:
            li_items.append(
                '<li class="page-item active">'
                '<a class="page-link">{p}</a>'
                '</li>'.format(p=p)
            )
        else:
            li_items.append(
                '<li class="page-item">'
                '<a class="page-link" href="{url}">{p}</a>'
                '</li>'.format(url=make_url(p), p=p)
            )
        prev_num = p

    # Botón siguiente (chevron derecho)
    if page.next_page:
        li_items.append(
            '<li class="page-item">'
            '<a class="page-link" href="{url}">'
            '<i class="fa-thin fa-chevrons-right"></i>'
            '</a></li>'.format(url=make_url(page.next_page))
        )
    else:
        li_items.append(
            '<li class="page-item disabled">'
            '<a class="page-link">'
            '<i class="fa-thin fa-chevrons-right"></i>'
            '</a></li>'
        )

    html = (
        '<div class="pagination-wrapper">'
        '<ul class="pagination justify-content-center">'
        + ''.join(li_items) +
        '</ul>'
        '</div>'
    )
    return Markup(html)


def get_login_error_msg():
    """Lee y borra el mensaje de error de login almacenado en sesión.
    Se muestra una única vez en la página destino del redirect de CAS."""
    from ckan.common import session
    msg = session.pop('login_error_msg', None)
    if msg:
        session.modified = True
    return msg


def clear_login_error():
    """Endpoint GET que borra el mensaje de error de login de la sesión."""
    from ckan.common import session
    from flask import jsonify
    session.pop('login_error_msg', None)
    session.modified = True
    return jsonify({'ok': True}), 200


def new_activities_dummy():
    """
    Dummy helper to prevent crashes in CKAN 2.9+ where the
    h.new_activities() helper from ckanext-dashboard was removed.
    """
    return 0

_GROUP_CACHE_TTL = 60
_FREQ_TAGS_CACHE_TTL = 120


def get_freq_tags(lang='tags_es'):
    """
    Obtiene los 5 tags más frecuentes en el idioma indicado.
    Resultado cacheado en memoria con TTL para evitar un package_search
    por cada render de la página de inicio.
    """
    now = time.time()
    with _FREQ_TAGS_CACHE_LOCK:
        cached = _FREQ_TAGS_CACHE.get(lang)
        if cached and (now - cached[0]) < _FREQ_TAGS_CACHE_TTL:
            return cached[1]

    package = toolkit.get_action('package_search')(data_dict={
        'rows': 0,
        'facet.field': ['tags_en', 'tags_ca', 'tags_es']
    })
    items = package["search_facets"].get(lang, {}).get("items", [])
    items_ordenados = sorted(items, key=lambda item: item['count'], reverse=True)
    tags_limit_5 = [item['display_name'] for item in items_ordenados[:5]]

    with _FREQ_TAGS_CACHE_LOCK:
        _FREQ_TAGS_CACHE[lang] = (now, tags_limit_5)
    return tags_limit_5


def get_tag(tag_id):
    try:
        tag_dict = toolkit.get_action('tag_show')(
            {}, {'id': tag_id})
        return tag_dict
    except toolkit.ObjectNotFound:
        return None


def get_group(group_id):
    """
    Devuelve el dict de un grupo. Resultado cacheado por ID con TTL para
    evitar una acción group_show por cada ítem de faceta o dropdown.
    """
    now = time.time()
    with _GROUP_CACHE_LOCK:
        cached = _GROUP_CACHE.get(group_id)
        if cached and (now - cached[0]) < _GROUP_CACHE_TTL:
            return cached[1]

    group_dict = toolkit.get_action('group_show')(data_dict={'id': group_id})

    with _GROUP_CACHE_LOCK:
        _GROUP_CACHE[group_id] = (now, group_dict)
    return group_dict


def get_groups_dict():
    """
    Devuelve un dict {name: group_dict} con todos los grupos activos,
    cargados en una sola acción group_list. Úsese en plantillas para
    evitar el patrón N+1 de get_group por ítem.
    """
    groups = toolkit.get_action('group_list')(data_dict={
        'all_fields': True,
        'include_extras': True,
    })
    return {g['name']: g for g in groups}

def get_license(license_id):
    return Package.get_license_register().get(license_id)

def schema_get_label_for_facet(facet, schema_type='dataset'):
    scheming_field = sh.scheming_field_by_name(
        sh.scheming_get_dataset_schema(schema_type)['dataset_fields'],
        facet)
    # Not a scheming field don't create a labeler and use the default

    if scheming_field is None:
        return None

    choices = sh.scheming_field_choices(scheming_field)
    # Not a choices field, don't create a labeler and use the default

    if choices is None:
        return None

    def get_label_for_field(field):
        return sh.scheming_choices_label(choices, field['name'])

    return get_label_for_field

def get_facet_items_dict(facet, limit=None, exclude_active=False, default_sort=True):
    """ Metodo que devuelve los items de un facet
    """
    if not c.search_facets or \
            not c.search_facets.get(facet) or \
            not c.search_facets.get(facet).get('items'):
        return []

    # Calcular el idioma una sola vez fuera del bucle (P2)
    language = sh.lang()
    # Convertir params a frozenset una sola vez para evitar reconstructing el iterador por ítem
    active_params = set(request.params.items())

    facets = []

    for facet_item in c.search_facets.get(facet)['items']:
        if not len(facet_item['name'].strip()):
            continue

        display_name = h.get_translated(facet_item, 'name') or facet_item.get('display_name')
        title_translated = facet_item.get('title_translated', {})

        if language in title_translated:
            display_name = title_translated[language]

        facets.append({
            'active': (facet, facet_item['name']) in active_params,
            'name': facet_item['name'],
            'count': facet_item['count'],
            'display_name': display_name
        })

    if default_sort:
        facets = sorted(facets, key=lambda item: item['count'], reverse=True)
    else:
        facets = sorted(facets, key=lambda item: item['display_name'])

    if limit is not None and limit > 0:
        return facets[:limit]
    return facets

def get_group_pagination_limit():
    """
    Devuelve el límite de paginación para grupos definida en el archivo
    de configuración etc/config.json
    """

    with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as json_file:
        json_data = json.loads(json_file.read())
        # Se asume que es un número entero, en otro caso habrá que hacer cast con int()
        return json_data['metadata']['groupPaginationLimit']


def get_all_groups():
    '''Return a list of all the groups
    '''
    items_per_page = get_group_pagination_limit()
    page = h.get_page_number(request.params) or 1
    data_dict = {
        'all_fields': True,
        'limit': items_per_page,
        'offset': items_per_page * (page - 1),
        'include_extras': True,
    }

    groups = toolkit.get_action('group_list')(data_dict=data_dict)
    return groups


def get_count_all_datasets():
    '''Returns the total number or datasets
    '''
    package_list = toolkit.get_action('package_search')(data_dict={})
    count = package_list.get('count')

    return count


def package_showcase_list(context):
    '''Returns a list of showcase from a dataset
    '''
    showcase_list = []
    package_dict = toolkit.get_action('ckanext_package_showcase_list')(
        {}, {'package_id': context.pkg_dict['id']})
    for package in package_dict:
        showcase_dict = toolkit.get_action(
            'ckanext_showcase_show')({}, {'id': package['id']})
        showcase_list.append(showcase_dict)
    return showcase_list


def get_delink_value():
    '''Returns the delink value
    '''
    return config.get('ckanext.gobcangroups.flag.for.delink', 'load_manual')


def get_legal_notice_license():
    '''Returns the license entry (from the shared license register, see
    etc/licenses/ckan-licenses.json) configured as this deployment's legal notice,
    or None if not configured
    '''
    license_id = config.get('ckanext.edatostheme.legal_notice_license_id', '')
    return get_license(license_id) if license_id else None


def get_legal_notice_url():
    '''Returns the legal notice URL for this deployment, or an empty string if not configured
    '''
    license = get_legal_notice_license()
    return license._data.get('url', '') if license else ''


def get_legal_notice_label():
    '''Returns the legal notice link label for this deployment, or an empty string if not configured
    '''
    license = get_legal_notice_license()
    return license._data.get('title', '') if license else ''


def abort_redirect():
    abort(403, _(u'Not authorized to see this page'))


def get_url(endpoint, key):
    """
    Metodo generico que devolvera la URL del header o footer segun la clave que se pase
    :param json_config: Fichero de configuracion cargado como un diccionario JSON
    :param key: Clave para buscar el header o footer
    """
    url = "%s/properties/%s.json" % (endpoint, key)
    headers = {
        'Content-Type': 'application/json'
    }
    header_request = requests.get(url=url, headers=headers, timeout=_REQUESTS_TIMEOUT).content
    json_header_request = json.loads(header_request)

    return json_header_request['value']


def get_request_lang(cookie_name):
    """
    Devuelve el idioma de la cookie si existe, o el idioma resuelto por CKAN, o el locale por defecto.
    
    :param cookie_name: Nombre de la cookie que contiene el idioma preferido del usuario
    Fallback: idioma resuelto por CKAN en la URL o el locale por defecto configurado.
    """
    lang = request.cookies.get(cookie_name) if cookie_name else None
    if not lang:
        try:
            lang = toolkit.h.lang()
        except Exception:
            lang = None
    if not lang:
        lang = config.get('ckan.locale_default', 'es')
    return lang


def get_theme():
    """
    Lee el theme del query param '?theme=' y si no existe, de la cookie 'theme'.
    Solo devuelve el valor si es uno de los temas aceptados.
    """
    theme = request.args.get('theme') or request.cookies.get('theme')
    return theme


def save_header(header):
    """
    Metodo que guarda el header como template

    :param header: Codigo del header en formato string que se va a guardar
    """

    #header = header.replace(b'&gt;', b'>').decode('utf8')
    #header = "{% block header_wrapper %}" + header + "{% endblock %}"
    with codecs.open(HEADER_PATH, 'w', encoding='utf8') as header_file:
        header_file.truncate(0)
        header_file.seek(0)
        header_file.write(header)


def get_header_url(json_config):
    """
    Devuelve la URL del header con el idioma del usuario.
    
    :param json_config: Configuracion cargada como diccionario JSON
    """
    endpoint = json_config['metadata']['endpoint']
    header_key = json_config['metadata']['navbarPathKey']
    cookie_key = json_config['metadata'].get('cookieKey')
    endpoint = json_config['metadata']['endpoint']
    title = json_config['metadata']['appName']
    navbar_url = get_url(endpoint, header_key)
    url = "%s?appName=%s&appId=%s&appUrl=%s" % (navbar_url, title, APP_ID_FOR_ANALYTICS, json_config['metadata']['siteURL'])

    theme = get_theme()
    if theme:
        url = "%s&organisation=%s" % (url, theme)

    # Obtener el nombre real de la cookie una sola vez
    cookie_name = get_url(endpoint, cookie_key) if cookie_key else None
    # Idioma del request: cookie > idioma CKAN > locale por defecto
    request_lang = get_request_lang(cookie_name)

    if cookie_name:
        url = "%s&%s=%s" % (url, cookie_name, request_lang)

    return url


def get_app_style_css_url():
    """
    Devuelve la URL del CSS standalone de complementos-apps (estilos
    generales y variables --edatos-*), leida de la propiedad
    'metamac.app.style.css.url' en el servicio de metadatos comun.

    Pensado para enlazarse con <link rel="stylesheet"> en paginas sin
    cabecera (p. ej. el iframe de package/snippets/resource_view_embed.html),
    que no reciben las variables --edatos-* porque estas se definen dentro
    del HTML del header/footer externo y esas paginas no lo renderizan.
    """
    try:
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            endpoint = json_config['metadata']['endpoint']
            css_key = json_config['metadata']['cssPathKey']
            url = get_url(endpoint, css_key)

            theme = get_theme()
            if theme:
                url = "%s?organisation=%s" % (url, theme)

            return url
    except Exception as e:
        log.error("Error al obtener la URL del CSS de complementos-apps: %s", e)
        return ""


def get_app_fontawesome_css_url():
    """
    Devuelve la URL del CSS de Font Awesome PRO (peso "Light", usado por los
    iconos de la barra de DataTables Buttons en la vista de recurso), leida
    de la propiedad 'fontawesomeCssPath' en config.json y combinada con el
    host del 'endpoint' del servicio de metadatos comun (este ultimo ya
    varia por cliente/entorno), para no hardcodear el dominio.
    """
    try:
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            endpoint = json_config['metadata']['endpoint']
            path = json_config['metadata']['fontawesomeCssPath']
            parsed_endpoint = urlparse(endpoint)
            return "%s://%s%s" % (parsed_endpoint.scheme, parsed_endpoint.netloc, path)
    except Exception as e:
        log.error("Error al obtener la URL del CSS de Font Awesome: %s", e)
        return ""


def get_altered_header(header, json_config):
    """
    Metodo que modifica el header para hacer que contenga los botones
    dinamicos que se generan para esta aplicacion en concreto.

    :param header: Codigo HTML del Header que se va a modificar
    :param json_config: Fichero de configuracion cargado como
                        un diccionario JSON
    """
    alteredHeader = header

    # Annadimos el boton hamburguesa
    soup = BeautifulSoup(alteredHeader, 'html.parser')
    container = soup.find(
        class_='d-flex justify-content-end align-items-center')

    if container is not None:
        with codecs.open(BURGER_BUTTON_PATH, 'r', encoding='utf8') as burger_button_file:
            code = burger_button_file.read()
            container.append(BeautifulSoup(code, 'html.parser'))
            alteredHeader = soup.prettify('utf-8')
            
            
    # Reemplazar titulo por el titulo con funcion de traduccion
    title = json_config['metadata']['appName']
    
    div = soup.find('div', id='title-bar')
    
    if div:
        span = div.find('span')
        if span and title.lower() in span.text.strip().lower():
            span.string = _(title)

    alteredHeader = soup.prettify('utf-8')

    alteredHeader = alteredHeader.replace(b'&gt;', b'>').decode('utf8')

    return alteredHeader


def get_html_header():
    """
    Descarga, modifica y devuelve el HTML del header en cada petición,
    sin caché. No lee ni escribe ficheros en disco.
    """
    try:
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
        html = requests.get(
            url=get_header_url(json_config), timeout=_REQUESTS_TIMEOUT).content
        altered = get_altered_header(header=html, json_config=json_config)
        return render_template_string(altered)
    except Exception as exc:
        log.warning('edatostheme: error al obtener header: %s', exc)
        return ''

# Map de vistas que se quieren restringir acceso
REDIRECT_VIEWS = (
    # route, view, function    
    ('/user/register', 'abort_redirect', abort_redirect),

)

class EdatosthemePlugin(plugins.SingletonPlugin, DefaultTranslation):
    plugins.implements(plugins.ITranslation)
    plugins.implements(plugins.IBlueprint)
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)
    plugins.implements(plugins.IPackageController, inherit=True)
    plugins.implements(plugins.IFacets)

    # IConfigurer

    def __get_footer_ulr(self, json_config):
        """
        Metodo que devuelve la URL del footer
        :param json_config: Fichero de configuracion cargado como un diccionario JSON
        """
        footer_key = json_config['metadata']['footerPathKey']
        endpoint = json_config['metadata']['endpoint']
        return "%s?appName=%s&appUrl=%s" % (get_url(endpoint, footer_key),
                                            json_config['metadata']['appName'],
                                            json_config['metadata']['siteURL'])

    def __get_favicon_url(self, json_config):
        """
        Metodo que devuelve la URL del favicon
        :param
            json_config: Fichero de configuracion cargado como diccionario JSON
        """
        favicon_key = json_config['metadata']['favicon']
        endpoint = json_config['metadata']['endpoint']
        return "%s?appName=%s&appUrl=%s" % (get_url(endpoint, favicon_key),
                                            json_config['metadata']['appName'],
                                            json_config['metadata']['siteURL'])


    def __save_footer(self, footer):
        """
        Metodo que guarda el footer como template

        :param footer: Codigo del footer en formato string que se va a guardar
        """
        with codecs.open(FOOTER_PATH, 'w', encoding='utf8') as footer_file:
            footer_file.write(footer)

    def __save_favicon(self, favicon):
        """
        Metodo para guardar el favicon

        :param favicon: Imagen descargada a guardar en la extension
        """
        with open(FAVICON_PATH, 'wb') as favicon_file:
            favicon_file.write(favicon)

    def __save_script(self, script_content):
        """
        Metodo para guardad el script

        :param script: Script
        """
        with codecs.open(SCRIPT_PATH, 'w', encoding='utf8') as script_file:
            script_file.write(self.__config_properties_filler(
                script_content=script_content
            ))

    def __config_properties_filler(self, script_content):
        """
        Metodo que rellena las variables
        """
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())

            site_url = json_config['metadata']['siteURL']
            regexp_site_url = site_url.replace('/', '\/').replace('.', '\.')
            if not config.get('ckan.locales_offered', None):
                raise RuntimeError(
                    '"ckan.locales_offered" is required for plugin: {0}'
                    .format(self.name))
                
            site_languages = config.get('ckan.locales_offered')
            if isinstance(site_languages, list):
                site_languages = ' '.join(site_languages)
                
            updated_script = script_content.replace(
                'FILL_SITE_URL', site_url).replace(
                'FILL_REGEXP_SITE_URL', regexp_site_url).replace(
                'FILL_SITE_LANGUAGES', site_languages)

            return updated_script

    def _load_footer(self):
        """
        Metodo que carga las templates para FOOTER
        """
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            footer = requests.get(
                url=self.__get_footer_ulr(json_config),
                timeout=_REQUESTS_TIMEOUT).content

            footer = footer.decode('utf-8')

            self.__save_footer(footer=footer)

    def _load_favicon(self):
        """
        Metodo que carga el favicon
        """
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            favicon = requests.get(
                url=self.__get_favicon_url(json_config),
                timeout=_REQUESTS_TIMEOUT).content
            self.__save_favicon(favicon=favicon)

    def _i18n_script_filler(self):
        """
        Metodo que incrusta en el script de i18n los valores de la config
        necesarias para su funcionamiento
        """
        with codecs.open(SCRIPT_TEMPLATE, 'r', encoding='utf8') as script_template:
            script_content = script_template.read()
            self.__save_script(script_content)

    # IConfigurer

    def update_config(self, config_):
        self._load_footer()
        self._load_favicon()
        self._i18n_script_filler()
        toolkit.add_template_directory(config_, '../templates')
        toolkit.add_public_directory(config_, '../public')
        toolkit.add_resource('../assets', 'ckanext-edatostheme')

    # IBlueprint
    def get_blueprint(self):
        edatos = Blueprint('istac_theme', self.__module__)

        if REDIRECT_VIEWS:
            for route_, view_, function_ in REDIRECT_VIEWS:
                edatos.add_url_rule(route_, view_, function_)

        edatos.add_url_rule(
            '/user/clear_login_error',
            'clear_login_error',
            clear_login_error,
            methods=['GET'],
        )

        return [edatos]

    # ITemplateHelpers

    def get_helpers(self):
        '''Register the get_all_groups function as a template helper function.
        '''
        return {
            'edatostheme_get_all_groups': get_all_groups,
            'edatostheme_get_count_all_datasets': get_count_all_datasets,
            'package_showcase_list': package_showcase_list,
            'edatostheme_get_delink_value': get_delink_value,
            'edatos_get_legal_notice_url': get_legal_notice_url,
            'edatos_get_legal_notice_label': get_legal_notice_label,
            'edatos_get_header': get_html_header,
            'edatos_get_app_style_css_url': get_app_style_css_url,
            'edatos_get_app_fontawesome_css_url': get_app_fontawesome_css_url,
            'edatos_get_facet_items_dict': get_facet_items_dict,
            'edatos_schema_get_label_for_facet': schema_get_label_for_facet,
            'edatos_get_license': get_license,
            'edatos_get_group': get_group,
            'edatos_get_groups_dict': get_groups_dict,
            'edatos_get_tag': get_tag,
            'edatos_get_freq_tags': get_freq_tags,
            'new_activities': new_activities_dummy,
            'edatos_get_login_error_msg': get_login_error_msg,
            'edatos_pager': edatos_pager,
        }

    # ITranslation

    def i18n_directory(self):
        return I18N_DIR

    # IPackageController
    def before_dataset_index(self, data_dict):
        """Metodo para realizar el indexado de las etiquetas i18n 
        en el index de solr correspondiente
        """
        if 'multilingual_tags' in data_dict:
            tags = json.loads(data_dict.get('extras_multilingual_tags', '{}'))
            data_dict['tags_en'] = tags.get('en', [])
            data_dict['tags_ca'] = tags.get('ca', [])
            data_dict['tags_es'] = tags.get('es', [])
        data_dict['multilingual_tags'] = []
        return data_dict
    
    # IFacets
    
    def dataset_facets(self, facets_dict, package_type):
        '''Add new search facet dictionary for datasets.
        '''
        reordered_facet_dict = OrderedDict({
            'groups': toolkit._('Groups'),
            'tags_en': toolkit._('Tags'),
            'tags_ca': toolkit._('Tags'),
            'tags_es': toolkit._('Tags'),
            'res_format': toolkit._('Formats'),
            'license_id': toolkit._('Licences'),
        })

        return reordered_facet_dict
    
    def group_facets(self, facets_dict, group_type, package_type):
        '''Modify and return the ``facets_dict`` for a group's page.
        '''
        return self.dataset_facets(facets_dict, package_type)

    def organization_facets(self, facets_dict, organization_type, package_type):
        '''Modify and return the ``facets_dict`` for an organization's page.
        '''
        return self.dataset_facets(facets_dict, package_type)
