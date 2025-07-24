import logging
import ckan.plugins as plugins
import ckan.plugins.toolkit as toolkit

from ckan.lib.uploader import get_uploader

from ckanext.edatosscheming import validators, helpers

log = logging.getLogger(__name__)


class EdatosschemingPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.IValidators)
    plugins.implements(plugins.ITemplateHelpers)
    plugins.implements(plugins.IMapper)

    # IConfigurer

    def update_config(self, config_):
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

    # IMapper
    
    def before_update(self, context, data_dict):
        """Hook to modify data_dict before update."""
        log.debug("Before update hook called for EdatosschemingPlugin")
        # Call the helper function to update the data_dict
        # helpers.before_update(self, context, data_dict)
        uploader = get_uploader('organization')
        uploader.update_data_dict(
            data_dict,
            url_field='image_url',
            file_field='upload',
            clear_field='clear_upload'
        )