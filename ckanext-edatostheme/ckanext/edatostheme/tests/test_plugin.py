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


def test_theme_is_a_plugin():
    """Check that the extension is a valid plugin."""
    p = plugin.EdatosthemePlugin()
    # SingletonPlugin lives in ckan.plugins, not in the toolkit, since CKAN 2.9.
    assert isinstance(p, plugins.SingletonPlugin)


def _write_config(tmp_path, metadata):
    config_file = tmp_path / 'config.json'
    config_file.write_text(json.dumps({'metadata': metadata}), encoding='utf8')
    return str(config_file)


def _clear_property_cache(monkeypatch):
    monkeypatch.setattr(plugin, '_resolved_properties', {})
    monkeypatch.setattr(plugin, '_property_attempts', {})


class TestGetProperty:
    """`get_property` must hit the metadata service once, not once per render."""

    def test_property_is_fetched_once_and_then_cached(self, monkeypatch, tmp_path):
        _clear_property_cache(monkeypatch)
        monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
            'endpoint': 'http://metadata.example/api',
            'cookieKey': 'metamac.internationalization.cookieId',
        }))
        calls = []
        monkeypatch.setattr(plugin, 'get_url', lambda endpoint, key: (
            calls.append((endpoint, key)) or 'chosenLocale'))

        assert plugin.get_property('cookieKey') == 'chosenLocale'
        assert plugin.get_property('cookieKey') == 'chosenLocale'

        assert calls == [('http://metadata.example/api',
                          'metamac.internationalization.cookieId')]

    def test_failure_is_not_retried_until_the_interval_has_passed(
            self, monkeypatch, tmp_path):
        _clear_property_cache(monkeypatch)
        monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
            'endpoint': 'http://metadata.example/api',
            'cookieKey': 'metamac.internationalization.cookieId',
        }))
        calls = []

        def failing_get_url(endpoint, key):
            calls.append(key)
            raise IOError('metadata service unreachable')

        monkeypatch.setattr(plugin, 'get_url', failing_get_url)

        now = [1000.0]
        monkeypatch.setattr(plugin.time, 'monotonic', lambda: now[0])

        assert plugin.get_property('cookieKey') is None
        assert plugin.get_property('cookieKey') is None
        assert len(calls) == 1, 'a failed property must not be retried per render'

        now[0] += plugin._PROPERTY_RETRY_INTERVAL + 1
        assert plugin.get_property('cookieKey') is None
        assert len(calls) == 2, 'a failed property must be retried eventually'

    def test_missing_key_in_config_resolves_to_nothing(self, monkeypatch, tmp_path):
        _clear_property_cache(monkeypatch)
        monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
            'endpoint': 'http://metadata.example/api',
        }))
        monkeypatch.setattr(plugin, 'get_url', lambda endpoint, key: 'unexpected')

        assert plugin.get_property('cookieKey') is None


class TestGetHeaderUrl:
    """The header URL is built server side for the browser to fetch."""

    def _setup(self, monkeypatch, tmp_path, navbar_url='http://apps.example/header.html',
               lang='en', theme=None):
        monkeypatch.setattr(plugin, 'CONFIG_FILE_PATH', _write_config(tmp_path, {
            'endpoint': 'http://metadata.example/api',
            'appName': 'Open Data Catalog',
            'siteURL': 'https://example.org/catalogo/',
            'cookieKey': 'metamac.internationalization.cookieId',
        }))
        monkeypatch.setattr(plugin, 'get_property',
                            lambda key: navbar_url if key == 'navbarPathKey' else None)
        monkeypatch.setattr(plugin, 'get_request_lang', lambda cookie_name: lang)
        monkeypatch.setattr(plugin, 'get_theme', lambda: theme)
        # Identity translation: the real one needs a request context.
        monkeypatch.setattr(plugin, '_', lambda message: message)
        monkeypatch.setattr(plugin, 'get_url', lambda endpoint, key: 'chosenLocale')

    def test_url_carries_the_app_and_language_parameters(self, monkeypatch, tmp_path):
        self._setup(monkeypatch, tmp_path, lang='en')

        url = plugin.get_header_url()

        assert url.startswith('http://apps.example/header.html?')
        assert 'appName=Open+Data+Catalog' in url
        assert 'appId=%s' % plugin.APP_ID_FOR_ANALYTICS in url
        assert 'appUrl=https%3A%2F%2Fexample.org%2Fcatalogo%2F' in url
        assert 'chosenLocale=en' in url
        assert 'organisation' not in url

    def test_theme_is_passed_as_organisation(self, monkeypatch, tmp_path):
        self._setup(monkeypatch, tmp_path, theme='ibestat')

        assert 'organisation=ibestat' in plugin.get_header_url()

    def test_url_is_empty_when_the_property_cannot_be_resolved(
            self, monkeypatch, tmp_path):
        self._setup(monkeypatch, tmp_path, navbar_url=None)

        assert plugin.get_header_url() == ''
