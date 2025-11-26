import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from ckanext.showcase.plugin import ShowcasePlugin
from ckanext.edatosshowcase import views

class EdatosshowcasePlugin(ShowcasePlugin, plugins.SingletonPlugin):
    plugins.implements(plugins.IDatasetForm)
    plugins.implements(plugins.IConfigurable, inherit=True)
    plugins.implements(plugins.IBlueprint, inherit=True)

    #IDatasetForm

    def package_types(self):
        return []

    def search_template(self):
        return "showcase/search.html"

    def read_template(self):
        return "showcase/read.html"

    def edit_template(self):
        return 'showcase/edit.html'

    #IConfigurer

    def update_config(self, config):
        super().update_config(config)
        toolkit.add_template_directory(config, '../templates')
        toolkit.add_public_directory(config, '../public')

    #IBlueprint
    
    def get_blueprint(self):
        return views.get_blueprints()

