"""Regression test for the anonymous redirect guard.

With ckan.auth.public_user_details = false the access is already closed, but
CKAN closes it with abort(403) - and the HAProxy in front has

    http-response redirect location .../error/403.html if { status 403 }

which swaps any 403 for a generic infrastructure error page ("have you checked
you are on the right VPN?"). That is both wrong and unhelpful for someone who
simply is not logged in, and it hands HTML to API clients.

redirect_anonymous_from_restricted_endpoints (plugin/__init__.py) runs as a
before_app_request, so it fires before the view calls check_access: no 403 is
ever produced and the proxy has nothing to intercept.

A fix on the infrastructure side was attempted and did not take, so this guard
stays. Do not remove it again without re-checking that a 403 comes through
clean - see docs/datos-personales-acceso-anonimo.md.

The parametrisation walks ANONYMOUS_RESTRICTED_ENDPOINTS itself, so adding an
endpoint to the frozenset without covering it here is not possible.
"""
import pytest

from ckan.plugins import toolkit

from ckanext.edatostheme.plugin import (
    ANONYMOUS_REQUIRED_ENDPOINTS,
    ANONYMOUS_RESTRICTED_ENDPOINTS,
)


# url_for needs *some* value for the placeholders; the guard matches on the
# endpoint before the view resolves them, so a dummy is enough.
URL_KWARGS = {
    'activity.package_history': {'id': 'x', 'activity_id': 'x'},
    'activity.resource_history': {'id': 'x', 'resource_id': 'x',
                                  'activity_id': 'x'},
    'user.api_token_revoke': {'id': 'x', 'jti': 'x'},
}
NO_KWARGS = {
    'user.index',
    'activity.package_changes_multiple',
    'activity.group_changes_multiple',
    'activity.organization_changes_multiple',
}

# POST-only rules: a GET dies in Flask's routing before any before_request
# handler runs, so they have to be exercised with the right method.
POST_ONLY = {'user.api_token_revoke'}


def _url_for(endpoint):
    if endpoint in NO_KWARGS:
        return toolkit.url_for(endpoint)
    return toolkit.url_for(endpoint, **URL_KWARGS.get(endpoint, {'id': 'x'}))


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins')
@pytest.mark.parametrize('endpoint', sorted(ANONYMOUS_RESTRICTED_ENDPOINTS))
def test_anonymous_is_redirected_to_login(app, endpoint):
    request = app.post if endpoint in POST_ONLY else app.get

    response = request(_url_for(endpoint), status=302, follow_redirects=False)

    assert response.headers['location'] == toolkit.url_for(
        'user.login', _external=True)


@pytest.mark.ckan_config('ckan.plugins', 'activity edatostheme')
@pytest.mark.usefixtures('with_plugins')
@pytest.mark.parametrize('endpoint', sorted(ANONYMOUS_REQUIRED_ENDPOINTS))
def test_login_flow_stays_reachable(app, endpoint):
    """Guarding any of these would turn the redirect into an infinite loop."""
    response = app.get(_url_for(endpoint), follow_redirects=False)

    assert response.status_code != 302 or (
        response.headers['location'] != toolkit.url_for(
            'user.login', _external=True))


def test_restricted_and_required_never_overlap():
    assert not (ANONYMOUS_RESTRICTED_ENDPOINTS & ANONYMOUS_REQUIRED_ENDPOINTS)
