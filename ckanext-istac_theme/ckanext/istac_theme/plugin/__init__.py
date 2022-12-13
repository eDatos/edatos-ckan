# -*- coding: UTF-8 -*-
import codecs
import json
import os

import ckan.lib.base as base
import ckan.lib.helpers as h
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
import requests
from bs4 import BeautifulSoup
from ckan.common import request
from ckan.lib.plugins import DefaultTranslation
from ckantoolkit import config
from flask import Blueprint

abort = base.abort


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


dirname = os.path.dirname(__file__)
CONFIG_FILE_PATH = os.path.join(dirname, '../etc/config.json')
FOOTER_PATH = os.path.join(dirname, '../templates/footer.html')
HEADER_PATH = os.path.join(dirname, '../templates/header.html')
HEADER_WHITE_BAR_PATH = os.path.join(
    dirname, '../code_templates/header_white_bar.html')
BURGER_BUTTON_PATH = os.path.join(
    dirname, '../code_templates/burger_button.html')

HERE = os.path.abspath(os.path.dirname(__file__))
I18N_DIR = os.path.join(HERE, "../i18n")

# Map de vistas que se quieren restringir acceso
REDIRECT_VIEWS = (
    #route, view, function
    ('/user/register', 'abort_redirect', abort_redirect),
)


class IstacThemePlugin(plugins.SingletonPlugin, DefaultTranslation):
    plugins.implements(plugins.ITranslation)
    plugins.implements(plugins.IBlueprint)
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.ITemplateHelpers)

    # IConfigurer

    def __get_altered_header(self, header, json_config):
        """
        Metodo que modifica el header para hacer que contenga los botones 
        dinamicos que se generan para esta aplicacion en concreto.

        :param header: Codigo HTML del Header que se va a modificar
        :param json_config: Fichero de configuracion cargado como 
                            un diccionario JSON
        """
        container_class = json_config['metadata']['htmlCodeClass']
        alteredHeader = header

        with codecs.open(HEADER_WHITE_BAR_PATH, 'r', encoding='utf8') as white_bar_file:
            code = white_bar_file.read()
            # Annadimos los botones en la barra blanca
            soup = BeautifulSoup(alteredHeader, 'html.parser')
            container = soup.find(id=container_class)
            container.append(BeautifulSoup(code, 'html.parser'))
            alteredHeader = soup.prettify('utf-8')

            # Annadimos el boton hamburguesa
            soup = BeautifulSoup(alteredHeader, 'html.parser')
            container = soup.find(
                class_='d-flex justify-content-end align-items-center')

        if container is not None:
            with codecs.open(BURGER_BUTTON_PATH, 'r', encoding='utf8') as burger_button_file:
                code = burger_button_file.read()
                container.append(BeautifulSoup(code, 'html.parser'))
                alteredHeader = soup.prettify('utf-8')

        alteredHeader = alteredHeader.replace(b'&gt;', b'>').decode('utf8')
        return "{% block header_wrapper %}" + alteredHeader + "{% endblock %}"

    def __get_url(self, endpoint, key):
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

    def __get_header_url(self, json_config):
        """
        Metodo que devuelve la URL del header
        :param json_config: Fichero de configuracion cargado como un diccionario JSON
        """
        header_key = json_config['metadata']['navbarPathKey']
        endpoint = json_config['metadata']['endpoint']
        return "%s?appName=%s&appUrl=%s" % (self.__get_url(endpoint, header_key),
                                            json_config['metadata']['appName'],
                                            json_config['metadata']['siteURL'])

    def __get_footer_ulr(self, json_config):
        """
        Metodo que devuelve la URL del footer
        :param json_config: Fichero de configuracion cargado como un diccionario JSON
        """
        footer_key = json_config['metadata']['footerPathKey']
        endpoint = json_config['metadata']['endpoint']
        return "%s?appName=%s&appUrl=%s" % (self.__get_url(endpoint, footer_key),
                                            json_config['metadata']['appName'],
                                            json_config['metadata']['siteURL'])

    def __save_footer(self, footer):
        """
        Metodo que guarda el footer como template

        :param footer: Codigo del footer en formato string que se va a guardar
        """
        with codecs.open(FOOTER_PATH, 'w', encoding='utf8') as footer_file:
            footer_file.write(footer)

    def __save_header(self, header):
        """
        Metodo que guarda el header como template

        :param header: Codigo del header en formato string que se va a guardar
        """
        with codecs.open(HEADER_PATH, 'w', encoding='utf8') as header_file:
            header_file.write(header)

    def _load_header_footer(self):
        """
        Metodo que carga las templates para HEADER y FOOTER
        """
        with codecs.open(CONFIG_FILE_PATH, 'r', encoding='utf8') as config_file:
            json_config = json.loads(config_file.read())
            header = requests.get(
                url=self.__get_header_url(json_config)).content
            header = self.__get_altered_header(
                header=header, json_config=json_config)
            footer = requests.get(
                url=self.__get_footer_ulr(json_config)).content

            footer = footer.decode('utf-8')

            self.__save_header(header=header)
            self.__save_footer(footer=footer)

    # IConfigurer

    def update_config(self, config_):
        self._load_header_footer()
        toolkit.add_template_directory(config_, '../templates')
        toolkit.add_public_directory(config_, '../public')
        toolkit.add_resource('../assets', 'ckanext-istac_theme')

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
            'istac_theme_get_all_groups': get_all_groups,
            'istac_theme_get_count_all_datasets': get_count_all_datasets,
            'package_showcase_list': package_showcase_list,
            'istac_theme_get_delink_value': get_delink_value,
        }

    # ITranslation

    def i18n_directory(self):
        return I18N_DIR
