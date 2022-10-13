from ckantoolkit import config

import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit


class GobcangroupsPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)

    FLAG_PROPERTY = None

    # IConfigurer

    def update_config(self, config_):
        toolkit.add_template_directory(config_, 'templates')
        toolkit.add_public_directory(config_, 'public')
        toolkit.add_resource('fanstatic', 'gobcangroups')

        # Load and parse flag attribute
        if not config.get('ckanext.gobcangroups.flag.for.delink', 'Manual'):
            raise RuntimeError(
                '"ckanext.gobcangroups.flag.for.delink: {0}'.format(self.name))
        # self.FLAG_PROPERTY = config.get('ckanext.gobcangroups.flag.for.delink')
        self.FLAG_PROPERTY = 'Histórico'
