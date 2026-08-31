"""Regression test for the member_list auth override.

ckan.auth.public_user_details = false closes the members pages, but only
for calls that carry object_type='user': the action's second
_check_access('group_show', ...) skips group_show's success shortcut only
when the request is about users. Omitting the argument takes the shortcut,
so /api/3/action/member_list?id=<group> still returned every member - user
ids and roles included - to anonymous visitors.

member_list_auth (plugin/__init__.py) closes both call shapes by not
allowing anonymous access at all.
"""
import pytest

import ckan.model as model
from ckan.plugins import toolkit
from ckan.tests import factories


def _anonymous_context():
    return {
        'model': model,
        'session': model.Session,
        'user': '',
        'auth_user_obj': None,
    }


# The bypass is the call WITHOUT object_type; the other shape is kept as a
# control so a regression that only fixes one of them still fails here.
CALL_SHAPES = [
    ('with object_type', {'object_type': 'user'}),
    ('without object_type', {}),
]


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.ckan_config('ckan.auth.public_user_details', False)
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('label, extra', CALL_SHAPES)
def test_member_list_denied_to_anonymous(label, extra):
    user = factories.User()
    org = factories.Organization(
        users=[{'name': user['name'], 'capacity': 'admin'}])

    data_dict = dict({'id': org['name']}, **extra)

    with pytest.raises(toolkit.NotAuthorized):
        toolkit.get_action('member_list')(_anonymous_context(), data_dict)


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.ckan_config('ckan.auth.public_user_details', False)
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('label, extra', CALL_SHAPES)
def test_member_list_still_works_for_members(label, extra):
    user = factories.User()
    org = factories.Organization(
        users=[{'name': user['name'], 'capacity': 'admin'}])

    data_dict = dict({'id': org['name']}, **extra)
    context = {
        'model': model,
        'session': model.Session,
        'user': user['name'],
    }

    members = toolkit.get_action('member_list')(context, data_dict)

    assert any(row[1] == 'user' for row in members)


@pytest.mark.ckan_config('ckan.plugins', 'edatostheme')
@pytest.mark.ckan_config('ckan.auth.public_user_details', False)
@pytest.mark.usefixtures('with_plugins', 'clean_db')
def test_member_list_api_denied_to_anonymous(app):
    user = factories.User()
    org = factories.Organization(
        users=[{'name': user['name'], 'capacity': 'admin'}])

    response = app.get(
        '/api/3/action/member_list?id=%s' % org['name'], status=403)

    assert user['id'] not in response.get_data(as_text=True)
