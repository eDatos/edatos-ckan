"""Regression test for the activity stream privacy fix.

Anonymous visitors must not be able to read a public dataset/group/
organization's activity stream (actor names, profile links, revision
diffs); logged-in users must still be able to. Also guards against the
group/organization views crashing with a raw 500 instead of a clean 403
(see handle_not_authorized in plugin/__init__.py).
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
def test_activity_stream_hidden_from_anonymous_users(app, endpoint, factory, key):
    obj = factory()
    url = toolkit.url_for(endpoint, id=obj[key])

    response = app.get(url)

    assert response.status_code in (401, 403)


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
