import ckan.plugins as p
import ckan.plugins.toolkit as toolkit
from ckanext.showcase.plugin import ShowcasePlugin

class EdatosshowcasePlugin(ShowcasePlugin):
    p.implements(p.IDatasetForm)
    p.implements(p.IConfigurable)

    def package_types(self):
        return []

    def update_config(self, config):
        super(EdatosshowcasePlugin, self).update_config(config)  


