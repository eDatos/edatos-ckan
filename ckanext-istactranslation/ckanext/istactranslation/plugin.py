import os
import sys
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit


class IstactranslationPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.ITranslation)

    # ITranslation

    # The following methods copied from ckan.lib.plugins.DefaultTranslation so
    # we don't have to mix it into the class. This means we can use Showcase
    # even if ITranslation isn't available (less than 2.5).

    def i18n_directory(self):
        '''Change the directory of the *.mo translation files

        The default implementation assumes the plugin is
        ckanext/myplugin/plugin.py and the translations are stored in
        i18n/
        '''
        # assume plugin is called ckanext.<myplugin>.<...>.PluginClass
        extension_module_name = '.'.join(self.__module__.split('.')[0:2])
        module = sys.modules[extension_module_name]
        return os.path.join(os.path.dirname(module.__file__), 'i18n')

    def i18n_locales(self):
        '''Change the list of locales that this plugin handles

        By default the will assume any directory in subdirectory in the
        directory defined by self.directory() is a locale handled by this
        plugin
        '''
        directory = self.i18n_directory()
        return [d for
                d in os.listdir(directory)
                if os.path.isdir(os.path.join(directory, d))]

    def i18n_domain(self):
        '''Change the gettext domain handled by this plugin

        This implementation assumes the gettext domain is
        ckanext-{extension name}, hence your pot, po and mo files should be
        named ckanext-{extension name}.mo'''
        return 'ckanext-{name}'.format(name=toolkit.config.get('ckan.plugins'))
