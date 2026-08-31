"""Regression test for the activity detail guard (history/changes pages).

package_activity_list et al. (see test_actions.py) only gate the activity
*list* actions. The per-revision detail pages (history diff, changes diff)
render via ckanext.activity's own activity_show/activity_diff actions,
whose auth functions check dataset/group visibility only, not login state
- so a direct URL to e.g. /dataset/changes/<activity_id> still exposed
actor names and full diffs to anonymous visitors even after that fix.
redirect_anonymous_from_activity_detail (plugin/__init__.py) closes that
with a blueprint before_request redirect to the login page, since raising
NotAuthorized here would hit the same reverse-proxy-swallows-403 problem
that moved package_activity_list off that approach.
"""
import pytest

from ckan.model import Session
from ckan.plugins import toolkit
from ckan.tests import factories
from ckanext.activity.model import Activity


@pytest.fixture()
def clean_db(reset_db, migrate_db_for):
    """Override core's clean_db to also apply ckanext-activity's migrations.

    reset_db() drops the schema and replays core alembic only, which
    recreates the pre-2.10 `activity` table (no `permission_labels`
    column), so any factory call here blows up on activity insert. Same
    workaround as ckanext/activity/tests/conftest.py in core. Kept
    module-local: migrate_db_for('activity') aborts when the activity
    plugin isn't loaded, which is the case for the other test modules.
    """
    reset_db()
    migrate_db_for('activity')


# The guard matches on endpoint before the view resolves its id, so any
# placeholder id reaches it for anonymous requests.
ANONYMOUS_ROUTES = [
    ('activity.package_history', {'id': 'x', 'activity_id': 'x'}),
    ('activity.package_changes', {'id': 'x'}),
    ('activity.package_changes_multiple', {}),
    ('activity.group_changes', {'id': 'x'}),
    ('activity.organization_changes', {'id': 'x'}),
    ('activity.group_changes_multiple', {}),
    ('activity.organization_changes_multiple', {}),
]


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, url_kwargs', ANONYMOUS_ROUTES)
def test_activity_detail_redirects_anonymous_users(app, endpoint, url_kwargs):
    url = toolkit.url_for(endpoint, **url_kwargs)

    response = app.get(url, status=302, follow_redirects=False)

    assert response.headers['location'] == toolkit.url_for(
        'user.login', _external=True)


def _latest_activity_id(object_id):
    return (
        Session.query(Activity)
        .filter_by(object_id=object_id)
        .order_by(Activity.timestamp.desc())
        .first()
        .id
    )


LOGGED_IN_ROUTES = [
    ('activity.package_history', factories.Dataset,
     lambda obj, activity_id: {'id': obj['id'], 'activity_id': activity_id}),
    ('activity.package_changes', factories.Dataset,
     lambda obj, activity_id: {'id': activity_id}),
    ('activity.group_changes', factories.Group,
     lambda obj, activity_id: {'id': activity_id}),
    ('activity.organization_changes', factories.Organization,
     lambda obj, activity_id: {'id': activity_id}),
]


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins', 'clean_db')
@pytest.mark.parametrize('endpoint, factory, url_kwargs_for', LOGGED_IN_ROUTES)
def test_activity_detail_visible_to_logged_in_users(
        app, endpoint, factory, url_kwargs_for):
    user = factories.User()
    obj = factory()
    activity_id = _latest_activity_id(obj['id'])
    url = toolkit.url_for(endpoint, **url_kwargs_for(obj, activity_id))

    response = app.get(
        url, extra_environ={'REMOTE_USER': user['name'].encode('ascii')})

    assert response.status_code == 200
