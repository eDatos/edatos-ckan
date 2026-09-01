"""Regression test: the API tokens page is closed to anonymous visitors.

core's ApiTokenView (ckan/views/user.py) already check_access api_token_list
and abort(403), so this only pins that behaviour down - nothing in this
extension should ever reopen it.

This used to assert a 302 to the login page, from a before_request redirect
that existed only because HAProxy turned every 403 into a redirect to
/error/403.html. That is fixed in the proxy now, so the plain 403 stands.
"""
import pytest

from ckan.plugins import toolkit
from ckan.tests import factories


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
def test_api_tokens_denied_to_anonymous(app):
    user = factories.User()

    app.get(toolkit.url_for('user.api_tokens', id=user['name']), status=403)


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
def test_api_tokens_visible_to_logged_in_users(app):
    user = factories.User()

    response = app.get(
        toolkit.url_for('user.api_tokens', id=user['name']),
        extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
