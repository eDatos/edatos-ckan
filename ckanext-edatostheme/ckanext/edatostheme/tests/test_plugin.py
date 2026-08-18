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

For functional tests that involve requests to the application, you can use the
`app` fixture:

    from ckan.plugins import toolkit

    def test_some_endpoint(app):

        url = toolkit.url_for('myblueprint.some_endpoint')

        response = app.get(url)

        assert response.status_code == 200


To temporary patch the CKAN configuration for the duration of a test you can use:

    import pytest

    @pytest.mark.ckan_config("ckanext.myext.some_key", "some_value")
    def test_some_action():
        pass
"""
import json

import ckan.plugins as plugins

import ckanext.edatostheme.plugin as plugin


def test_theme_is_a_plugin():
    """Check that the extension is a valid plugin."""
    p = plugin.EdatosthemePlugin()
    # SingletonPlugin lives in ckan.plugins, not in the toolkit, since CKAN 2.9.
    assert isinstance(p, plugins.SingletonPlugin)


def _write_config(tmp_path, metadata):
    config_file = tmp_path / 'config.json'
    config_file.write_text(json.dumps({'metadata': metadata}), encoding='utf8')
    return str(config_file)


def test_lang_cookie_name_is_resolved_at_startup(monkeypatch, tmp_path):
    """The cookie name is fetched once at startup, not on every render."""
    monkeypatch.setattr(plugin, '_lang_cookie_name', 'stale')
    monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
        'endpoint': 'http://metadata.example/api',
        'cookieKey': 'metamac.internationalization.cookieId',
    }))
    calls = []

    def fake_get_url(endpoint, key):
        calls.append((endpoint, key))
        return 'chosenLocale'

    monkeypatch.setattr(plugin, 'get_url', fake_get_url)

    plugin.EdatosthemePlugin()._load_lang_cookie_name()

    assert plugin._lang_cookie_name == 'chosenLocale'
    assert calls == [('http://metadata.example/api',
                      'metamac.internationalization.cookieId')]


def test_lang_cookie_name_falls_back_when_metadata_service_is_down(
        monkeypatch, tmp_path):
    """A metadata service outage at startup must not drop the cookie name."""
    monkeypatch.setattr(plugin, '_lang_cookie_name',
                        plugin.DEFAULT_LANG_COOKIE_NAME)
    monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
        'endpoint': 'http://metadata.example/api',
        'cookieKey': 'metamac.internationalization.cookieId',
    }))

    def boom(endpoint, key):
        raise IOError('metadata service unreachable')

    monkeypatch.setattr(plugin, 'get_url', boom)

    plugin.EdatosthemePlugin()._load_lang_cookie_name()

    assert plugin._lang_cookie_name == plugin.DEFAULT_LANG_COOKIE_NAME
