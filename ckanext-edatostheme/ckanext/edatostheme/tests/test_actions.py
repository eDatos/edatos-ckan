"""Regression test for the activity stream privacy fix.

Anonymous visitors must not see a public dataset/group/organization's
activity stream (actor names, profile links, revision diffs); logged-in
users must still see it. The activity stream page must keep returning
HTTP 200 for anonymous users (not 403) — in this deployment's
environments, any 403 gets intercepted by the reverse proxy and
redirected to a generic branded error page, discarding whatever specific
message the app tried to show. So access is denied by emptying the data
(with a flash banner), not by raising NotAuthorized.
"""
import pytest

from ckan.plugins import toolkit
from ckan.tests import factories


ACTIVITY_ROUTES = [
    ('activity.package_activity', factories.Dataset, 'id'),
    ('activity.group_activity', factories.Group, 'id'),
    ('activity.organization_activity', factories.Organization, 'id'),
]


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory, key', ACTIVITY_ROUTES)
def test_activity_stream_empty_for_anonymous_users(app, endpoint, factory, key):
    obj = factory()
    url = toolkit.url_for(endpoint, id=obj[key])

    response = app.get(url)

    assert response.status_code == 200
    assert 'Debes iniciar sesión' in response.body


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory, key', ACTIVITY_ROUTES)
def test_activity_stream_visible_to_logged_in_users(app, endpoint, factory, key):
    user = factories.User()
    obj = factory()
    url = toolkit.url_for(endpoint, id=obj[key])

    response = app.get(
        url, extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
    assert 'Debes iniciar sesión' not in response.body
