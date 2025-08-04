import codecs
import json
import os

import requests

import logging
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit


from ckanext.edatosscheming import validators, helpers

log = logging.getLogger(__name__)

dirname = os.path.dirname(__file__)
CONFIG_FILE_PATH = os.path.join(dirname, '../etc/config.json')
SChEMAS_FOLDER_PATH = os.path.join(dirname, '../schemas')
SCHEMAS_TEMPLATES_FOLDER_PATH = os.path.join(dirname, '../schemas_templates')


#  def __get_languages(self, json_config):
#         """
#         Metodo que devuelve los lenguajes del cmetadata
#         :param json_config: Fichero de configuracion cargado como un diccionario JSON
#         https://estadisticas.arte-consultores.com/cmetadata/v1.0/properties/metamac.internationalization.languages.json
#         """
#         availableLanguages = json_config['metadata']['availablesLanguages']
#         endpoint = json_config['metadata']['endpoint']
#         return "%s?appName=%s&appUrl=%s" % (get_url(endpoint, availableLanguages),
#                                             json_config['metadata']['appName'],
#                                             json_config['metadata']['siteURL'])

def get_url(endpoint, key):
    """
    Metodo generico que devolvera la lista de lenguajes
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

def get_languages():
    """
    Metodo que devuelve los lenguajes del cmetadata
    :return: Lista de lenguajes
    """
    with codecs.open(CONFIG_FILE_PATH, 'r', 'utf-8') as config_file:
        json_config = json.load(config_file)
        endpoint = json_config['metadata']['endpoint']
        availableLanguages = json_config['metadata']['availablesLanguages']
        return get_url(endpoint, availableLanguages)

def _languages_properties_filler(self):
    pass

class EdatosschemingPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.IValidators)
    plugins.implements(plugins.ITemplateHelpers)


    def __save_schema(self, schema_content):
        """
        Metodo para guardar el schema 

        :param schema: schema
        """
        with codecs.open(SCRIPT_PATH, 'w', encoding='utf8') as schema_file:
            schema_file.write(self.__language_properties_filler(
                schema_content=schema_content
            ))

    def __language_properties_filler(self, schema_content):
        """
        Metodo que rellena los lenguajes de las propiedades del cmetadata
        :return: None
        """
        languages = get_languages() # ['es', 'en', 'ca', 'gl', 'eu']
        with codecs.open(SChEMAS_FOLDER_PATH, 'r', 'utf-8') as config_file:
            json_config = json.load(config_file)
        

    def __languages_schemas_filler(self)):
        """
        AQUI DEBO DE LLAMAR EL JSON DE LOS LENGUAJES Y PARA CADA SCHEMA DEBO DE RELLENAR SU FILL CORRESPONDIENTE. NO OLVIDAR EL CKAN.INI
        Metodo para rellenar los lenguajes de los schemas segun la configuracion
        en el commun-metadata
        """
        SCHEMAS = ['datasets.json', 
                   'showcases.json', 
                   'organizations.json',
                   'groups.json',]
        for schema in SCHEMAS: 
            path = os.path.join(SCHEMAS_TEMPLATES_FOLDER_PATH, schema) 
            with codecs.open(path, 'w', 'utf-8') as schema_file:
                schema_content = schema_file.read()
                self.__save_schema(schema_content)
                


    # IConfigurer

    def update_config(self, config_):
        # Generar schemas con los lenguajes disponibles
        # self._languages_dataset_schemas()
        # self._languages_dataset_schemas()
        self.__languages_schemas_filler()
        toolkit.add_template_directory(config_, '../templates')
        toolkit.add_public_directory(config_, '../public')
        toolkit.add_resource('../fanstatic',
                             '../ckanext-edatosscheming')

    # IValidatos

    def get_validators(self):
        return {
            'uri_text': validators.uri_text,
            'uri_text_output': validators.uri_text_output,
            'date_frequency': validators.date_frequency,
            'date_frequency_output': validators.date_frequency_output,
            'date_period': validators.date_period,
            'date_period_output': validators.date_period_output,
            'multilanguage_url': validators.multilanguage_url,
            'multiple_uri_text': validators.multiple_uri_text,
            'multiple_uri_text_output': validators.multiple_uri_text_output,
            'multiple_required_language': validators.multiple_required_language,
            'multiple_one_value': validators.multiple_one_value,
            'select_organization': validators.select_organization,
            'select_license' : validators.select_license,
            'tags_html_detected': validators.tags_html_detected,
            'url_encode': validators.url_encode,
            'multiple_url_encode': validators.multiple_url_encode,
            'copy_fluent_keywords_to_tags': validators.copy_fluent_keywords_to_tags
        }

    # ITemplateHelpers

    def get_helpers(self):
        return {
            'dge_dataset_form_value': helpers.dge_dataset_form_value,
            'dge_dataset_form_lang_and_value': helpers.dge_dataset_form_lang_and_value,
            'dge_dataset_form_organization_list': helpers.dge_dataset_form_organization_list,
            'dge_multiple_field_required': helpers.dge_multiple_field_required,
        }
