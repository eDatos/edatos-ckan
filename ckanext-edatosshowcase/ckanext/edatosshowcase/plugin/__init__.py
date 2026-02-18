import logging
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit
from ckanext.showcase.plugin import ShowcasePlugin
from ckanext.edatosshowcase import views

log = logging.getLogger(__name__)

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

    def _add_to_pkg_dict(self, context, pkg_dict):
        '''ValidationError que captura cuando el showcase no es valido, para evitar que falle la carga del dataset'''
        try:
            return super()._add_to_pkg_dict(context, pkg_dict)
        except toolkit.ValidationError as e:
            log.warning('Failed to add showcase data to package %s: %s', 
                       pkg_dict.get('id'), str(e))
            # Return pkg_dict without showcase modifications if validation fails
            pkg_dict['num_datasets'] = 0
            return pkg_dict

