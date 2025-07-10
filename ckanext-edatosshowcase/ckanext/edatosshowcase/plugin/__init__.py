import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from ckanext.showcase.plugin import ShowcasePlugin
from ckanext.showcase.logic import action as showcase_action
from ckanext.edatosshowcase import views
from flask import Blueprint

class EdatosshowcasePlugin(ShowcasePlugin, plugins.SingletonPlugin):
    plugins.implements(plugins.IDatasetForm)
    plugins.implements(plugins.IConfigurable, inherit=True)
    plugins.implements(plugins.IBlueprint, inherit=True)

    #IDatasetForm

    def package_types(self):
        print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAG")
        return []

    def search_template(self):
        return "showcase/search.html"

    def read_template(self):
        print("CAOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOS")
        return "showcase/read.html"

    def edit_template(self):
        return 'showcase/edit.html'

    #IConfigurer

    def update_config(self, config):
        super().update_config(config)
        toolkit.add_template_directory(config, '../templates')
        toolkit.add_public_directory(config, '../public')
        toolkit.add_resource('../assets', 'ckanext-edatosshowcase')
        toolkit.add_resource('../fanstatic', 'ckanext-edatosshowcase')
        #super(EdatosshowcasePlugin, self).update_config(config)  # Llama a la configuración original de Showcase
        # Aquí puedes agregar o ajustar configuraciones adicionales según sea necesario

    #IBlueprint
    
    def get_blueprint(self):
        return views.get_blueprints()


    #IRoutes
    def get_actions(self):
        action_functions = {
            'edatosshowcase.delete': views.read.showcase_read,
            'edatosshowcase.search': views.search.showcase_search,
        }
        return action_functions