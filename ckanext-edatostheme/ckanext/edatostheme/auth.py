# -*- coding: UTF-8 -*-
"""Authorization overrides.

CKAN's core activity_list auth functions (ckanext.activity.logic.auth) are
decorated with @auth_allow_anonymous_access, so anonymous requests reach
them and are then granted access to any activity stream whose underlying
package/group/organization/user is public — which for a public open-data
catalog means anonymous visitors can read the full activity stream (actor
names, profile links, and revision diffs).

package_activity_list et al. are already registered by the core `activity`
plugin (not by ckan core itself), so overriding them outright collides with
CKAN's plugin-vs-plugin auth conflict check ("already implemented in
'activity'"); the supported way to change a plugin-registered auth function
is a chained auth function (see IAuthFunctions docs), which wraps the
existing implementation instead of replacing it.
"""
import ckan.plugins.toolkit as toolkit


def _require_authenticated_user(next_auth, context, data_dict):
    if not context.get('user'):
        return {
            'success': False,
            'msg': toolkit._('Not authorized to see this page'),
        }
    return next_auth(context, data_dict)


@toolkit.chained_auth_function
def package_activity_list(next_auth, context, data_dict):
    return _require_authenticated_user(next_auth, context, data_dict)


@toolkit.chained_auth_function
def group_activity_list(next_auth, context, data_dict):
    return _require_authenticated_user(next_auth, context, data_dict)


@toolkit.chained_auth_function
def organization_activity_list(next_auth, context, data_dict):
    return _require_authenticated_user(next_auth, context, data_dict)


@toolkit.chained_auth_function
def user_activity_list(next_auth, context, data_dict):
    return _require_authenticated_user(next_auth, context, data_dict)
