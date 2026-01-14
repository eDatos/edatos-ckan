from flask import Blueprint
import ckan.lib.base as base

import logging
from collections import OrderedDict

import ckantoolkit as toolkit

import ckan.plugins as plugins
import ckan.logic as logic
import ckan.views.dataset as dataset
from functools import partial
from urllib.parse import urlencode
import ckan.model as model
from ckan.plugins.toolkit import g, config, request, _, asbool
import ckan.lib.helpers as h
from ckan.lib.search import SearchError, SearchQueryError

from ckan.views.home import CACHE_PARAMETERS
import ckan.lib.navl.dictization_functions as dict_fns
from ckanext.showcase import views, utils as showcase_utils

_setup_template_variables = dataset._setup_template_variables
NotAuthorized = logic.NotAuthorized
check_access = logic.check_access
_encode_params = dataset._encode_params
get_action = logic.get_action
tuplize_dict = logic.tuplize_dict
clean_dict = logic.clean_dict
parse_params = logic.parse_params
NotFound = logic.NotFound



log = logging.getLogger(__name__)

DATASET_TYPE_NAME = showcase_utils.DATASET_TYPE_NAME

showcase = Blueprint('edatosshowcase_blueprint', __name__)

def drill_down_url(alternative_url=None, **by):
    return h.add_url_param(
        alternative_url=alternative_url,
        controller='edatosshowcase_blueprint',
        action='search',
        new_params=by
    )

def remove_field(package_type, key, value=None, replace=None):
    url = h.url_for('edatosshowcase_blueprint.search')
    return h.remove_url_param(
        key,
        value=value,
        replace=replace,
        alternative_url=url
    )

def index(package_type):
    extra_vars = {}

    try:
        context = {
            'model': model,
            'user': g.user,
            'auth_user_obj': g.userobj
        }
    except NotAuthorized:
        toolkit.abort(403, _('Not authorized to see this page'))

    # unicode format (decoded from utf8)
    extra_vars['q'] = q = request.args.get('q', '')

    extra_vars['query_error'] = False
    page = h.get_page_number(request.args)

    limit = int(config.get('ckan.datasets_per_page', 21))

    # most search operations should reset the page counter:
    params_nopage = [(k, v) for k, v in request.args.items(multi=True)
                     if k != 'page']

    extra_vars['drill_down_url'] = drill_down_url
    extra_vars['remove_field'] = partial(remove_field, package_type)

    sort_by = request.args.get('sort', None)
    params_nosort = [(k, v) for k, v in params_nopage if k != 'sort']

    extra_vars['sort_by'] = partial(dataset._sort_by, params_nosort, package_type)

    if not sort_by:
        sort_by_fields = []
    else:
        sort_by_fields = [field.split()[0] for field in sort_by.split(',')]
    extra_vars['sort_by_fields'] = sort_by_fields

    pager_url = partial(dataset._pager_url, params_nopage, package_type)

    search_url_params = urlencode(_encode_params(params_nopage))
    extra_vars['search_url_params'] = search_url_params

    details = dataset._get_search_details()
    extra_vars['fields'] = details['fields']
    extra_vars['fields_grouped'] = details['fields_grouped']
    fq = details['fq']
    search_extras = details['search_extras']

    context = {
        'model': model,
        'session': model.Session,
        'user': g.user,
        'for_view': True,
        'auth_user_obj': g.userobj
    }

    # Unless changed via config options, don't show other dataset
    # types any search page. Potential alternatives are do show them
    # on the default search page (dataset) or on one other search page
    search_all_type = config.get('ckan.search.show_all_types', 'dataset')
    search_all = False

    try:
        # If the "type" is set to True or False, convert to bool
        # and we know that no type was specified, so use traditional
        # behaviour of applying this only to dataset type
        search_all = asbool(search_all_type)
        search_all_type = 'dataset'
    # Otherwise we treat as a string representing a type
    except ValueError:
        search_all = True

    if not search_all or package_type != search_all_type:
        # Only show datasets of this particular type
        fq += ' +dataset_type:{type}'.format(type=package_type)

    facets = OrderedDict()

    default_facet_titles = {
        'organization': _('Organizations'),
        'groups': _('Groups'),
        'tags': _('Tags'),
        'res_format': _('Formats'),
        'license_id': _('Licenses'),
    }

    for facet in h.facets():
        if facet in default_facet_titles:
            facets[facet] = default_facet_titles[facet]
        else:
            facets[facet] = facet

    # Facet titles
    for plugin in plugins.PluginImplementations(plugins.IFacets):
        facets = plugin.dataset_facets(facets, package_type)

    extra_vars['facet_titles'] = facets
    data_dict = {
        'q': q,
        'fq': fq.strip(),
        'facet.field': list(facets.keys()),
        'rows': limit,
        'start': (page - 1) * limit,
        'sort': sort_by,
        'extras': search_extras,
        'include_private': asbool(
            config.get('ckan.search.default_include_private', True)
        ),
    }
    try:
        query = get_action('package_search')(context, data_dict)

        extra_vars['sort_by_selected'] = sort_by
        g.sort_by_selected = sort_by

        extra_vars['page'] = h.Page(
            collection=query['results'],
            page=page,
            url=pager_url,
            item_count=query['count'],
            items_per_page=limit
        )
        g.page = extra_vars["page"]
        extra_vars['search_facets'] = query['search_facets']
        g.search_facets = query['search_facets']
        g.facets = query['facets']
        extra_vars['page'].items = query['results']
    except SearchQueryError as se:
        # User's search parameters are invalid, in such a way that is not
        # achievable with the web interface, so return a proper error to
        # discourage spiders which are the main cause of this.
        log.info('Dataset search query rejected: %r', se.args)
        toolkit.abort(
            400,
            _('Invalid search query: {error_message}')
            .format(error_message=str(se))
        )
    except SearchError as se:
        # May be bad input from the user, but may also be more serious like
        # bad code causing a SOLR syntax error, or a problem connecting to
        # SOLR
        log.error('Dataset search error: %r', se.args)
        extra_vars['query_error'] = True
        g.facets = {}
        extra_vars['search_facets'] = {}
        extra_vars['page'] = h.Page(collection=[])

    g.search_facets_limits = {}
    for facet in extra_vars['search_facets'].keys():
        try:
            limit = int(
                request.args.get(
                    '_%s_limit' % facet,
                    int(config.get('search.facets.default', 10))
                )
            )
        except ValueError:
            toolkit.abort(
                400,
                _('Parameter u"{parameter_name}" is not '
                  'an integer').format(parameter_name='_%s_limit' % facet)
            )
        g.search_facets_limits[facet] = limit

    dataset._setup_template_variables(context, {}, package_type=package_type)

    extra_vars['dataset_type'] = package_type

    return toolkit.render(
        'edatosshowcase/search.html', extra_vars
    )


class CreateView(views.CreateView):

    def get(self, data=None, errors=None, error_summary=None):
        package_type = showcase_utils.DATASET_TYPE_NAME
        showcase_utils.check_new_view_auth()
        context = self._prepare()

        data = data or clean_dict(
            dict_fns.unflatten(
                tuplize_dict(
                    parse_params(request.args, ignore_keys=CACHE_PARAMETERS)
                )
            )
        )
        resources_json = h.json.dumps(data.get('resources', []))
        # convert tags if not supplied in data
        if data and not data.get('tag_string'):
            data['tag_string'] = ', '.join(
                h.dict_list_reduce(data.get('tags', {}), 'name')
            )

        errors = errors or {}
        error_summary = error_summary or {}
        # in the phased add dataset we need to know that
        # we have already completed stage 1
        stage = ['active']
        if data.get('state', '').startswith('draft'):
            stage = ['active', 'complete']

        # if we are creating from a group then this allows the group to be
        # set automatically
        data[
            'group_id'
        ] = request.args.get('group') or request.args.get('groups__0__id')

        form_vars = {
            'data': data,
            'errors': errors,
            'error_summary': error_summary,
            'action': 'new',
            'stage': stage,
            'dataset_type': package_type,
            'form_style': 'new'
        }
        errors_json = h.json.dumps(errors)

        # : remove
        g.resources_json = resources_json
        g.errors_json = errors_json

        _setup_template_variables(context, {}, package_type=package_type)

        new_template = 'edatosshowcase/new.html'
        return base.render(
            new_template,
            extra_vars={
                'form_vars': form_vars,
                'form_snippet': 'edatosshowcase/package_form.html',
                'dataset_type': package_type,
                'resources_json': resources_json,
                'errors_json': errors_json
            }
        )

    def post(self):
        data_dict = dataset.clean_dict(
            dataset.dict_fns.unflatten(
                dataset.tuplize_dict(dataset.parse_params(toolkit.request.form))))
        data_dict.update(
            dataset.clean_dict(
                dataset.dict_fns.unflatten(
                    dataset.tuplize_dict(dataset.parse_params(
                        toolkit.request.files)))))
        context = self._prepare()
        data_dict['type'] = showcase_utils.DATASET_TYPE_NAME
        context['message'] = data_dict.get('log_message', '')

        try:
            pkg_dict = toolkit.get_action('ckanext_showcase_create')(context,
                                                                data_dict)

        except toolkit.ValidationError as e:
            errors = e.error_dict
            error_summary = e.error_summary
            data_dict['state'] = 'none'
            return self.get(data_dict, errors, error_summary)

        # redirect to manage datasets
        url = h.url_for('showcase_blueprint.manage_datasets',
                        id=pkg_dict['name'])
        return h.redirect_to(url)


class EditView(views.EditView):
    def get(self, id, data=None, errors=None, error_summary=None):
        showcase_utils.check_new_view_auth()

        context = self._prepare()
        package_type = showcase_utils.DATASET_TYPE_NAME

        try:
            pkg_dict = get_action('package_show')(
                dict(context, for_view=True), {
                    'id': id
                }
            )
            context['for_edit'] = True
            old_data = get_action('package_show')(context, {'id': id})
            # old data is from the database and data is passed from the
            # user if there is a validation error. Use users data if there.
            if data:
                old_data.update(data)
            data = old_data
        except (NotFound, NotAuthorized):
            return base.abort(404, _('Dataset not found'))
        # are we doing a multiphase add?
        if data.get('state', '').startswith('draft'):
            g.form_action = h.url_for('{}.new'.format(package_type))
            g.form_style = 'new'

            return CreateView().get(
                package_type,
                data=data,
                errors=errors,
                error_summary=error_summary
            )

        pkg = context.get(u"package")
        resources_json = h.json.dumps(data.get('resources', []))

        try:
            check_access('package_update', context)
        except NotAuthorized:
            return base.abort(
                403,
                _('User %r not authorized to edit %s') % (g.user, id)
            )
        # convert tags if not supplied in data
        if data and not data.get('tag_string'):
            data['tag_string'] = ', '.join(
                h.dict_list_reduce(pkg_dict.get('tags', {}), 'name')
            )
        errors = errors or {}
        form_vars = {
            'data': data,
            'errors': errors,
            'error_summary': error_summary,
            'action': 'edit',
            'dataset_type': package_type,
            'form_style': 'edit'
        }
        errors_json = h.json.dumps(errors)

        # : remove
        # g.pkg = pkg
        # g.resources_json = resources_json
        # g.errors_json = errors_json

        _setup_template_variables(
            context, {'id': id}, package_type=package_type
        )

        # we have already completed stage 1
        form_vars['stage'] = ['active']
        if data.get('state', '').startswith('draft'):
            form_vars['stage'] = ['active', 'complete']

        edit_template = 'edatosshowcase/edit.html'
        return base.render(
            edit_template,
            extra_vars={
                'form_vars': form_vars,
                'form_snippet': 'edatosshowcase/package_form.html',
                'dataset_type': package_type,
                'pkg_dict': pkg_dict,
                'pkg': pkg,
                'resources_json': resources_json,
                'errors_json': errors_json
            }
        )

    def post(self, id):
        context = self._prepare()
        showcase_utils.check_edit_view_auth(id)

        data_dict = dataset.clean_dict(
            dataset.dict_fns.unflatten(
                dataset.tuplize_dict(dataset.parse_params(toolkit.request.form))))
        data_dict.update(
            dataset.clean_dict(
                dataset.dict_fns.unflatten(
                    dataset.tuplize_dict(dataset.parse_params(
                        toolkit.request.files)))))

        data_dict['id'] = id
        try:
            pkg = toolkit.get_action('ckanext_showcase_update')(context, data_dict)
        except toolkit.ValidationError as e:
            errors = e.error_dict
            error_summary = e.error_summary
            return self.get(id, data_dict, errors, error_summary)

        toolkit.c.pkg_dict = pkg

        # redirect to showcase details page
        url = h.url_for('edatosshowcase_blueprint.read', id=pkg['name'])
        return h.redirect_to(url)

def search():
    return index(DATASET_TYPE_NAME)

def edit(id):
    return 

def delete(id):
    return showcase_utils.delete_view(id)

def read(id):
    context = {
        'model': model,
        'session': model.Session,
        'user': toolkit.g.user or toolkit.author,
        'for_view': True,
        'auth_user_obj': toolkit.g.userobj
    }
    data_dict = {'id': id}

    # check if showcase exists
    try:
        pkg_dict = toolkit.get_action('package_show')(context, data_dict)
    except toolkit.ObjectNotFound:
        return toolkit.abort(404, _('Showcase not found'))
    except toolkit.NotAuthorized:
        return toolkit.abort(401, _('Unauthorized to read showcase'))

    # get showcase packages
    showcase_pkgs = toolkit.get_action('ckanext_showcase_package_list')(
        context, {
            'showcase_id': pkg_dict['id']
        })

    package_type = showcase_utils.DATASET_TYPE_NAME
    return toolkit.render('edatosshowcase/read.html',
                          extra_vars={'dataset_type': package_type,
                                      'pkg_dict': pkg_dict,
                                      'showcase_pkgs': showcase_pkgs})


showcase.add_url_rule('/showcase', view_func=search, strict_slashes=False)
showcase.add_url_rule('/showcase/new', 
                      view_func=CreateView.as_view('new'),
                      endpoint="new")
showcase.add_url_rule('/showcase/edit/<id>',
                        view_func=EditView.as_view('edit'),
                        methods=['GET', 'POST'])
showcase.add_url_rule('/showcase/delete/<id>',
                      view_func=delete,
                      methods=['GET', 'POST'],
                      endpoint="delete")
showcase.add_url_rule('/showcase/<id>', 
                      view_func=read,
                      endpoint="read")


def get_blueprints():
    return [showcase] + views.get_blueprints()
