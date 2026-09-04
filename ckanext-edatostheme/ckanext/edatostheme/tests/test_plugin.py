"""
Tests for plugin.py.

Tests are written using the pytest library (https://docs.pytest.org), and you
should read the testing guidelines in the CKAN docs:
https://docs.ckan.org/en/2.9/contributing/testing.html

CKAN 2.11 registers its own pytest fixtures; install this extension's
dev-requirements.txt inside the container to run them (see
docs/running-tests-in-docker.md). Do not install pytest-ckan, it targets
CKAN <= 2.8.

For instance, if your test involves database access you can use `clean_db` to
reset the database:

    import pytest

    from ckan.tests import factories

    @pytest.mark.usefixtures("clean_db")
    def test_some_action():

        dataset = factories.Dataset()

        # ...

To temporary patch the CKAN configuration for the duration of a test you can use:

    import pytest

    @pytest.mark.ckan_config("ckanext.myext.some_key", "some_value")
    def test_some_action():
        pass
"""
import json

import ckan.plugins as plugins

import ckanext.edatostheme.plugin as plugin
import ckan.plugins as plugins


def test_theme_is_a_plugin():
    """Check that the extension is a valid plugin."""
    p = plugin.EdatosthemePlugin()
    assert isinstance(p, plugins.SingletonPlugin)
