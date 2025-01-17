import ckan.plugins as p
import ckan.plugins.toolkit as toolkit
from ckanext.showcase.plugin import ShowcasePlugin

class EdatosshowcasePlugin(ShowcasePlugin):
    p.implements(p.IConfigurer)

    def update_config(self, config):
        toolkit.add_template_directory(config, 'templates')
        toolkit.add_public_directory(config, 'public')
        toolkit.add_resource('fanstatic', 'edatosshowcase')

    def package_types(self):
        return []  

