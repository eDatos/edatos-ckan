"""Regression test for the API tokens page guard.

core's ApiTokenView/api_token_revoke (ckan/views/user.py) abort(403) for
anonymous requests. In deployment that 403 is intercepted by the reverse
proxy and swapped for a generic infra error page instead of CKAN's login
prompt. redirect_anonymous_from_restricted_endpoints (plugin/__init__.py)
closes that with a blueprint before_request redirect to the login page,
mirroring the pattern used for the activity detail guard (see
test_activity_detail_guard.py) and shared with the members guard (see
test_members_guard.py).
"""
import pytest

from ckan.plugins import toolkit
from ckan.tests import factories


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
def test_api_tokens_redirects_anonymous_users(app):
    user = factories.User()
    url = toolkit.url_for('user.api_tokens', id=user['name'])

    response = app.get(url, status=302, follow_redirects=False)

    assert response.headers['location'] == toolkit.url_for(
        'user.login', _external=True)


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
def test_api_tokens_visible_to_logged_in_users(app):
    user = factories.User()
    url = toolkit.url_for('user.api_tokens', id=user['name'])

    response = app.get(
        url, extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
