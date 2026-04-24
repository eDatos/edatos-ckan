
# -*- coding: UTF-8 -*-
import codecs
import json
import os
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import requests
import ckanext.scheming.helpers as sh

from bs4 import BeautifulSoup
from ckan.common import _, request, c
from collections import OrderedDict
from ckan.model import Package
from ckan.model.tag import Tag
from ckan.lib.plugins import DefaultTranslation
from ckantoolkit import config, h, _, request, abort
from flask import Blueprint
from flask import request as fr


dirname = os.path.dirname(__file__)
CONFIG_FILE_PATH = os.path.join(dirname, '../etc/config.json')
FOOTER_PATH = os.path.join(dirname, '../templates/footer.html')
HEADER_PATH = os.path.join(dirname, '../templates/header_meta.html')
FAVICON_PATH = os.path.join(dirname, '../public/favicon.ico')
SCRIPT_PATH = os.path.join(dirname, '../assets/js/i18n.js')
BURGER_BUTTON_PATH = os.path.join(
    dirname, '../code_templates/burger_button.html')
SCRIPT_TEMPLATE = os.path.join(dirname, '../code_templates/i18n.js')

HERE = os.path.abspath(os.path.dirname(__file__))
I18N_DIR = os.path.join(HERE, "../i18n")
APP_ID_FOR_ANALYTICS = 'ckan-catalog'

def new_activities_dummy():
    """
    Dummy helper to prevent crashes in CKAN 2.9+ where the
    h.new_activities() helper from ckanext-dashboard was removed.
    """
    return 0

def get_freq_tags(lang='tags_es'):
    """
    Obtiene los facets de los datasets (package) usando package_search.
    Devuelve los 5 tags mas frecuentes en el idioma indicado
    :param lang: Idioma de los tags a recuperar
    """
    package = toolkit.get_action('package_search')(data_dict = {
        'rows': 0,
        'facet.field': ['tags_en', 'tags_ca', 'tags_es']
    })
    
    items = package["search_facets"][lang]["items"]
    items_ordenados = sorted(items, key=lambda item: item['count'], reverse=True)

    tags_limit_5 = [item['display_name'] for item in items_ordenados[:5]]
    return tags_limit_5
    

def get_tag(tag_id):
    try:
        tag_dict = toolkit.get_action('tag_show')(
            {}, {'id': tag_id})
        return tag_dict
    except toolkit.ObjectNotFound:
        return None

def get_group(group_id):
    try:
        group_dict = toolkit.get_action('group_show')(
            {}, {'id': group_id})
        return group_dict
    except toolkit.ObjectNotFound:
        return None

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

    facets = []

    for facet_item in c.search_facets.get(facet)['items']:
        if not len(facet_item['name'].strip()):
            continue

        display_name = h.get_translated(facet_item, 'name') or facet_item.get('display_name')
        title_translated = facet_item.get('title_translated', {})

        language = sh.lang()
        if language in title_translated:
            display_name = title_translated[language]

        facets.append({
            'active': (facet, facet_item['name']) in request.params.items(),
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
    header_request = requests.get(url=url, headers=headers).content
    json_header_request = json.loads(header_request)

    return json_header_request['value']


def get_header_url(json_config):
    """
    Metodo que devuelve la URL del header
    :param json_config: Fichero de configuracion cargado como un diccionario JSON
    """
    header_key = json_config['metadata']['navbarPathKey']
    endpoint = json_config['metadata']['endpoint']
    title_translated = _(json_config['metadata']['appName'])
    cookie_key = json_config['metadata'].get('cookieKey')

    base_url = "%s?appName=%s&appUrl=%s" % (
        get_url(endpoint, header_key),
        title_translated,
        json_config['metadata']['siteURL']
    )

    if cookie_key:
        #cookieId, se debe usar para rescatar el label de la cookie la respuesta se debe
        # de poner como parametro de llamada a la cabecera y el idioma que venga de la cookie
        request_lang = get_request_lang(get_url(endpoint, cookie_key))

        # Enviar al mismo nivel del appName el chosenLocale
        return "%s&%s=%s" % (base_url, get_url(endpoint, cookie_key), request_lang)

    return base_url


def get_request_lang(cookie_value):
    return request.cookies.get(cookie_value)


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
    Metodo que devuelve la URL del header
    :param json_config: Fichero de configuracion cargado como un diccionario JSON
    """
    header_key = json_config['metadata']['navbarPathKey']
    endpoint = json_config['metadata']['endpoint']
    cookie_key = json_config['metadata']['cookieKey']
    title_translated = _(json_config['metadata']['appName'])
    title = json_config['metadata']['appName']

    #cookieId, se debe usar para rescatar el label de la cookie la respuesta se debe
    # de poner como parametro de llamada a la cabecera y el idioma que venga de la cookie
    request_lang = get_request_lang(get_url(endpoint, cookie_key))

    # Enviar al mismo nivel del appName el chosenLocale
    return "%s?appName=%s&appUrl=%s&appId=%s&%s=%s" % (get_url(endpoint, header_key),
                                        title,
                                        json_config['metadata']['siteURL'],
                                        APP_ID_FOR_ANALYTICS,
                                        get_url(endpoint, cookie_key),
                                        request_lang
                                        )


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
            span.string = f"{{{{ _('{title}') }}}}"
            
    alteredHeader = soup.prettify('utf-8')

    alteredHeader = alteredHeader.replace(b'&gt;', b'>').decode('utf8')

    return "{% block header_wrapper %}" + alteredHeader + "{% endblock %}"



def load_header():
    """
    Metodo que carga las templates para HEADER
    """
    with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
        json_config = json.loads(config_file.read())
        # Se carga el header y se guarda como template
        header = requests.get(
            url=get_header_url(json_config)).content
        header = get_altered_header(
            header=header, json_config=json_config)

        save_header(header=header)

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
        pass

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
                url=self.__get_footer_ulr(json_config)).content

            footer = footer.decode('utf-8')

            self.__save_footer(footer=footer)

    def _load_favicon(self):
        """
        Metodo que carga el favicon
        """
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            favicon = requests.get(
                url=self.__get_favicon_url(json_config)).content
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
        # self._load_header_footer()
        self._load_footer()
        self._load_favicon()
        self._i18n_script_filler()
        toolkit.add_template_directory(config_, '../templates')
        toolkit.add_public_directory(config_, '../public')
        toolkit.add_resource('../assets', 'ckanext-edatostheme')

        # Registrar templates de edatostheme con máxima prioridad para que
        # sobreescriban los de ckanext-scheming y otros plugins
        templates_dir = os.path.join(os.path.dirname(__file__), '..', 'templates')
        templates_dir = os.path.abspath(templates_dir)
        extra_paths = config_.get('extra_template_paths', '')
        if extra_paths:
            config_['extra_template_paths'] = templates_dir + ',' + extra_paths
        else:
            config_['extra_template_paths'] = templates_dir

    # IBlueprint
    def get_blueprint(self):
        edatos = Blueprint('istac_theme', self.__module__)

        if REDIRECT_VIEWS:
            for route_, view_, function_ in REDIRECT_VIEWS:
                edatos.add_url_rule(route_, view_, function_)

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
            'edatos_get_header': load_header,
            'edatos_get_facet_items_dict': get_facet_items_dict,
            'edatos_schema_get_label_for_facet': schema_get_label_for_facet,
            'edatos_get_license': get_license,
            'edatos_get_group': get_group,
            'edatos_get_tag': get_tag,
            'edatos_get_freq_tags': get_freq_tags,
            'new_activities': new_activities_dummy,
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
