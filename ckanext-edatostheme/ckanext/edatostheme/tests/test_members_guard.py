"""Regression test: the members pages are closed to anonymous visitors.

core's members() view (ckan/views/group.py) only check_access('group_show'),
and its template renders every member's avatar, display name and a link to
their user page via h.linked_user(). What closes it is
ckan.auth.public_user_details = false: the view calls member_list with
object_type='user', so the action's second _check_access('group_show', ...)
skips the success shortcut in group_show's auth (ckan/logic/auth/get.py),
which is only taken when the request is NOT about users.

The config is set per environment (CKAN__AUTH__PUBLIC_USER_DETAILS), so it is
forced here rather than relied upon, or the test would silently pass on a
misconfigured box.

This used to assert a 302 to the login page, from a before_request redirect
that existed only because HAProxy turned every 403 into a redirect to
/error/403.html. That is fixed in the proxy now, so the plain 403 stands.
"""
import pytest

from ckan.plugins import toolkit
from ckan.tests import factories


MEMBERS_ROUTES = [
    ('group.members', factories.Group),
    ('organization.members', factories.Organization),
]


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.ckan_config('ckan.auth.public_user_details', False)
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory', MEMBERS_ROUTES)
def test_members_denied_to_anonymous(app, endpoint, factory):
    user = factories.User(fullname='Nombre Real Apellido')
    group = factory(users=[{'name': user['name'], 'capacity': 'admin'}])

    response = app.get(toolkit.url_for(endpoint, id=group['name']), status=403)

    body = response.get_data(as_text=True)
    assert user['fullname'] not in body
    assert user['name'] not in body


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.ckan_config('ckan.auth.public_user_details', False)
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory', MEMBERS_ROUTES)
def test_members_visible_to_logged_in_users(app, endpoint, factory):
    user = factories.User()
    group = factory(users=[{'name': user['name'], 'capacity': 'admin'}])

    response = app.get(
        toolkit.url_for(endpoint, id=group['name']),
        extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
