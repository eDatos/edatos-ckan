"""Regression test for the group/organization members page guard.

core's members() view (ckan/views/group.py) only check_access('group_show'),
which is public, so /group/members/<id> and /organization/members/<id> were
reachable anonymously and rendered every member's avatar, display name and a
link to their user page via h.linked_user(). Unlike the API tokens case there
is no 403 to intercept here - the page is simply public - but the fix is the
same before_request redirect, so both live in
redirect_anonymous_from_restricted_endpoints (plugin/__init__.py).

manage_members is not covered here on purpose: it already requires
group_edit_permissions in core.
"""
import pytest

from ckan.plugins import toolkit
from ckan.tests import factories


MEMBERS_ROUTES = [
    ('group.members', factories.Group),
    ('organization.members', factories.Organization),
]


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory', MEMBERS_ROUTES)
def test_members_redirects_anonymous_users(app, endpoint, factory):
    group = factory()
    url = toolkit.url_for(endpoint, id=group['name'])

    response = app.get(url, status=302, follow_redirects=False)

    assert response.headers['location'] == toolkit.url_for(
        'user.login', _external=True)


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory', MEMBERS_ROUTES)
def test_members_visible_to_logged_in_users(app, endpoint, factory):
    user = factories.User()
    group = factory(users=[{'name': user['name'], 'capacity': 'admin'}])
    url = toolkit.url_for(endpoint, id=group['name'])

    response = app.get(
        url, extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
