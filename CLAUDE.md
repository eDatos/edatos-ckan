# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains custom CKAN extensions for ISTAC (Instituto Canario de Estadística). CKAN is an open-source data management system for powering data hubs and open data portals. This project customizes CKAN with several extensions for authentication, theming, schema management, and federation capabilities.

## Architecture

### Extension Structure

The project consists of six CKAN extensions in separate directories:

1. **ckanext-cas**: CAS (Central Authentication Service) integration with ISTAC's authentication system
   - Plugin: `cas` (entry point: `ckanext.cas.plugin:CASClientPlugin`)
   - Manages user authentication, roles, and permissions from ISTAC's CAS server
   - Implements custom authentication flow with ticket validation (v2 service validation or v3 SAML validation)

2. **ckanext-edatostheme**: Visual theming and styling layer (active)
   - Plugin: `edatostheme` (entry point: `ckanext.edatostheme.plugin:EdatosthemePlugin`)
   - Provides custom templates, styles, and branding
   - Fetches header/footer from external metadata service on startup
   - Requires Apache reload to reflect changes from external resources

3. **ckanext-edatosscheming**: Schema definitions and custom validators
   - Plugin: `edatosscheming` (entry point: `ckanext.edatosscheming.plugin:EdatosschemingPlugin`)
   - Defines metadata schemas for datasets, organizations, groups, and showcases
   - Implements custom validators (URI validation, multilanguage support, date frequency/period)
   - Dynamically generates schemas from templates based on available languages from common-metadata service
   - Schema templates in `ckanext/edatosscheming/schemas_templates/`
   - Generated schemas in `ckanext/edatosscheming/schemas/`

4. **ckanext-edatosshowcase**: Showcase functionality
   - Plugin: `edatosshowcase` (entry point: `ckanext.edatosshowcase.plugin`)
   - Manages showcases (use case displays for datasets)

5. **ckanext-gobcangroups**: RDF federation with GPE (Gobierno de España)
   - Plugin: `gobcangroups` (entry point: `ckanext.gobcangroups.plugin:GobcangroupsPlugin`)
   - Handles dataset federation and unlinking from GPE catalog
   - Uses tags to flag datasets for delinking (default: "Manual" tag)

6. **ckanext-istactranslation**: (Deprecated) - Translations now integrated into ckanext-edatostheme

### Key Extension Dependencies

The extensions must be loaded in a specific order in `ckan.plugins` configuration. Pay attention to:
- `ckanext-edatosscheming` provides custom validators used by other schemas
- `ckanext-edatostheme` should be loaded after other extensions for template overrides
- `ckanext-istactranslation` is deprecated and should not be used

### Configuration Files

Configuration is organized by environment in the `etc/` directory:
- `etc/config/{organization}/{environment}/config.json` - Extension-specific configs per organization/environment
- `etc/licenses/ckan-licenses.json` - License definitions for federation mapping
- `etc/formats/resource_formats.json` - Resource format definitions
- `etc/dcat custom profile/gobcan_profile.py` - Custom DCAT profile for RDF federation
- `etc/db/common-metadata/postgresql/01-create/` - Database initialization scripts

## Development Commands

### Extension Installation

Each extension follows the standard CKAN extension installation pattern:

```bash
# Development installation for an extension
cd ckanext-{extension-name}
pip install -e .
pip install -r requirements.txt
pip install -r dev-requirements.txt  # if available
```

### Testing

Each extension has its own test configuration:

```bash
# Run tests for an extension (older extensions using nosetests)
cd ckanext-cas
nosetests --nologcapture --with-pylons=test.ini

# Run tests with coverage
nosetests --nologcapture --with-pylons=test.ini --with-coverage --cover-package=ckanext.cas --cover-inclusive --cover-erase --cover-tests

# Run tests for newer extensions (using pytest)
cd ckanext-edatosscheming
pytest --ckan-ini=test.ini
```

### Building Python Packages

To create distributable packages:

```bash
cd ckanext-{extension-name}
python setup.py sdist
```

## Docker Environment

The project includes a complete Docker setup based on the official [ckan-docker](https://github.com/ckan/ckan-docker) repository, located in `docker/ckan-docker/`.

### Quick Start

```bash
# Create Docker network (one time only)
docker network create ckan-net

# Navigate to docker directory
cd docker/ckan-docker

# Build images
docker compose build

# Start all services
docker compose up -d

# Check status
docker compose ps
```

### Access Information

- **CKAN Portal**: https://localhost:8443/ or https://192.168.10.110:8443/
- **Admin User**: ckan_admin
- **Admin Password**: test1234
- **CKAN Version**: 2.11.0

### Docker Services

The environment includes the following services:

1. **ckan**: Main CKAN application
   - Port: 5000 (internal)
   - All ISTAC extensions pre-installed
   - Health check: `/api/action/status_show`

2. **db**: PostgreSQL 16
   - Database: ckandb
   - Datastore: datastore
   - Includes initialization scripts for CKAN and Datastore databases

3. **solr**: Apache Solr 9 (CKAN index)
   - Port: 8983 (internal)
   - Custom schema: `docker/ckan-docker/src/solr/schema.xml`

4. **redis**: Redis 6 (background jobs)
   - Port: 6379 (internal)
   - Used by XLoader and Harvest extensions

5. **nginx**: Reverse proxy with SSL
   - Port: 8443 (HTTPS, exposed to host)
   - Self-signed SSL certificate generated on startup
   - Proxies requests to CKAN container

### Extension Installation in Docker

Extensions are installed during the Docker build process. The ISTAC extensions are located in:
- `docker/ckan-docker/src/extensions/` - Symlinked to root extensions

During build, the Dockerfile:
1. Clones the ckan-istac repository (branch: EDATOS-5261_ActualizacionCKANDockerizado)
2. Installs community extensions (xloader, geoview, showcase, dcat, harvest, fluent, scheming)
3. Installs ISTAC custom extensions (cas, edatosscheming, edatostheme, gobcangroups, edatosshowcase)
4. Sets required permissions on theme templates

### Environment Variables

All configuration is managed via `docker/ckan-docker/.env` file. Key variables:

```bash
# CKAN Core
CKAN_VERSION=2.11.0
CKAN_SITE_URL=https://192.168.10.110:8443/
CKAN__SITE_TITLE=Portal de datos abiertos ISTAC
CKAN__LOCALE_DEFAULT=es
CKAN__LOCALES_OFFERED=es ca en

# Database
POSTGRES_PASSWORD=postgres
CKAN_DB_USER=ckandbuser
CKAN_DB_PASSWORD=ckandbpassword

# Extensions
CKAN__PLUGINS=stats image_view text_view resource_proxy datatables_view datastore gobcangroups gobcan_harvester geojson_view shp_view cas edatosscheming xloader scheming_datasets scheming_groups scheming_organizations fluent envvars

# CAS Authentication
CKANEXT__CAS__LOGIN_URL=https://estadisticas.arte-consultores.com/authentication-service-internal/login
CKANEXT__CAS__LOGOUT_URL=https://estadisticas.arte-consultores.com/authentication-service-internal/logout
CKANEXT__CAS__SERVICE_VALIDATION_URL=https://estadisticas.arte-consultores.com/authentication-service-internal/p3/serviceValidate
CKANEXT__CAS__ADMIN_PROPERTY=ADMINISTRADOR
CKANEXT__CAS__MEMBER_PROPERTY=GESTOR
CKANEXT__CAS__BASE_PROPERTY=CATALOGO_DATOS

# Schemas
CKAN___SCHEMING__PRESETS=ckanext.scheming:presets.json ckanext.fluent:presets.json ckanext.dcat.schemas:presets.yaml ckanext.edatosscheming:schemas/presets.json
CKAN___SCHEMING__DATASET_SCHEMAS=ckanext.edatosscheming:schemas/datasets.json ckanext.edatosscheming:schemas/showcase.json
```

### Useful Docker Commands

```bash
# View logs in real-time
docker compose logs -f ckan

# View logs for specific service
docker compose logs -f nginx
docker compose logs -f db

# Execute CKAN commands
docker compose exec ckan ckan --config=/srv/app/ckan.ini user list
docker compose exec ckan ckan --config=/srv/app/ckan.ini sysadmin add username

# Restart specific service
docker compose restart ckan
docker compose restart nginx

# Stop all services
docker compose down

# Stop and remove volumes (WARNING: deletes data)
docker compose down -v

# Rebuild specific service
docker compose build ckan
docker compose up -d ckan

# Access container shell
docker compose exec ckan bash
docker compose exec db psql -U postgres

# Check resource usage
docker compose stats
```

### Volume Mounts

The following directories are mounted from host to containers:

```
docker/ckan-docker/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json
  → /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json

docker/ckan-docker/src/ckanext-edatosscheming/ckanext/edatosscheming/etc/config.json
  → /srv/app/src/ckanext-edatosscheming/ckanext/edatosscheming/etc/config.json

docker/ckan-docker/src/extensions/
  → /srv/app/src/src_extensions/
```

Named volumes for persistence:
- `ckan_storage` - Uploaded files and resources
- `pg_data` - PostgreSQL database
- `solr_data` - Solr search index
- `pip_cache` - Python package cache
- `site_packages` - Python installed packages

### Development Mode

For development with live code reloading, use the dev compose file:

```bash
# Build dev images
bin/compose build

# Install extensions from src
bin/install_src

# Start in dev mode
bin/compose up

# Generate new extension
bin/generate_extension

# Access CKAN shell
bin/shell

# Reload CKAN without restart
bin/reload
```

### Troubleshooting

**NGINX fails with "host not found in upstream 'ckan'":**
- This happens if NGINX starts before CKAN is ready
- The compose file has `depends_on` with health checks to prevent this
- Solution: `docker compose restart nginx`

**Database connection errors:**
- Ensure the `db` service is healthy: `docker compose ps`
- Check database logs: `docker compose logs db`
- Verify connection string in `.env` file

**Extension not loading:**
- Check if extension is in `CKAN__PLUGINS` in `.env`
- Rebuild CKAN image: `docker compose build ckan`
- Check CKAN logs for errors: `docker compose logs ckan | grep -i error`

**Port 8443 already in use:**
- Change `NGINX_SSLPORT_HOST` in `.env` to a different port
- Restart: `docker compose down && docker compose up -d`

### Docker Network

The setup uses an external network `ckan-net` to allow communication between containers. This network must be created before starting services:

```bash
docker network create ckan-net
```

All services connect to this network and can communicate using service names as hostnames (e.g., `ckan`, `db`, `solr`, `redis`).

## Important Configuration Properties

### CAS Authentication (ckanext-cas)

Required properties in CKAN config file:
```ini
ckanext.cas.user_mapping = email~email user~username fullname~full_name
ckanext.cas.login_url = http://cas-server/login
ckanext.cas.logout_url = http://cas-server/logout
ckanext.cas.application_url = https://ckan-instance
ckanext.cas.service_validation_url = http://cas-server/serviceValidate  # OR use saml_validation_url
ckanext.cas.admin_property = ADMINISTRADOR  # Role property for admin users
ckanext.cas.member_property = GESTOR  # Role property for member users
ckanext.cas.base_property = CATALOGO_DATOS  # Base permission property
ckanext.cas.single_sign_out = true
ckanext.cas.verify_certificate = true
```

### EdatosTheme Configuration

Configuration loaded from `ckanext/edatostheme/etc/config.json`:
- Contains metadata service endpoints for fetching header/footer
- Contains available languages configuration
- Requires `chmod 777` permissions on `templates/header.html` and `templates/footer.html` for dynamic updates

### GobcanGroups Configuration

```ini
ckanext.gobcangroups.flag.for.delink = Manual  # Tag name for delinking datasets from GPE
```

## Schema Management

Schemas are dynamically generated on CKAN startup:

1. Schema templates are stored in `ckanext/edatosscheming/schemas_templates/`
2. On startup, `EdatosschemingPlugin.update_config()` calls `__languages_schemas_filler()`
3. This fetches available languages from the common-metadata service
4. Templates are processed to replace `FILL_REQUIRED_LANGUAGE` with the primary language
5. Generated schemas are written to `ckanext/edatosscheming/schemas/`

Schemas exist for:
- datasets.json
- showcase.json
- organization.json
- group.json

Each schema defines field types, validators, form snippets, and display snippets.

## Custom Validators

The `ckanext-edatosscheming` extension provides custom validators in `ckanext/edatosscheming/validators.py`:

- `uri_text` / `uri_text_output` - URL validation with multilanguage support
- `multiple_uri_text` / `multiple_uri_text_output` - Multiple URL validation
- `date_frequency` / `date_frequency_output` - Frequency period validation
- `date_period` / `date_period_output` - Date period validation
- `multilanguage_url` - Multilanguage URL validation
- `multiple_required_language` - Validates required language fields
- `select_organization` / `select_license` - Organization and license selection
- `tags_html_detected` - HTML detection in tags
- `url_encode` / `multiple_url_encode` - URL encoding helpers
- `copy_fluent_keywords_to_tags` - Converts fluent keywords to CKAN tags

## Database Configuration

Database initialization scripts are in `etc/db/common-metadata/postgresql/01-create/`:
- `01-edatos-publisher-import-data.sql` contains publisher data imports
- The property `FILLME` in SQL scripts should be replaced with the concatenation of `site_url` and `root_path` from CKAN config

## Important Notes

### Apache Service Management

- Changes to external resources (header/footer from componentes-apps) require Apache reload:
  ```bash
  systemctl reload httpd
  ```
- Full restarts are needed for extension or configuration changes:
  ```bash
  systemctl restart httpd
  ```

### File Permissions

The theme extension requires specific permissions:
```bash
chmod 777 /path/to/ckanext-edatostheme/ckanext/edatostheme/templates/header.html
chmod 777 /path/to/ckanext-edatostheme/ckanext/edatostheme/templates/footer.html
```

### CKAN Version Compatibility

- ckanext-cas: Works with CKAN 2.6+
- ckanext-edatostheme: Designed for CKAN 2.9.0+
- Other extensions: Primarily targeted at CKAN 2.9+

### Python Version

Extensions target Python 3.8 (see setup.py classifiers), though some legacy code may reference Python 2.7.

## Code Structure Patterns

### Plugin Entry Points

All extensions follow the standard CKAN plugin pattern:
```python
class MyPlugin(plugins.SingletonPlugin):
    plugins.implements(plugins.IConfigurer)
    plugins.implements(plugins.IValidators)  # if providing validators
    plugins.implements(plugins.ITemplateHelpers)  # if providing template helpers
    plugins.implements(plugins.IAuthenticator)  # for auth plugins
    plugins.implements(plugins.IBlueprint)  # for route/blueprint registration
```

### Template Override Hierarchy

Templates in extensions override core CKAN templates. The load order matters:
- Later extensions in `ckan.plugins` can override templates from earlier extensions
- Template directory added via `toolkit.add_template_directory(config_, 'templates')`

### Blueprints and Routes

ckanext-cas implements custom routes via Flask blueprints:
- `/cas/callback` - CAS v2 service validation callback
- `/cas/saml_callback` - CAS v3 SAML validation callback
- `/cas/logout` - Logout endpoint

## Federation and RDF

The `gobcan_profile.py` custom DCAT profile in `etc/dcat custom profile/` defines:
- RDF mappings for federation with external catalogs
- Custom dataset serialization for DCAT compatibility
- Used by the ckanext-gobcangroups harvester

## Working with Multilanguage Content

Many fields support multilanguage input via the fluent extension pattern:
- Fields store JSON with language keys: `{"es": "Texto", "en": "Text"}`
- Custom display snippets in `ckanext/edatosscheming/templates/scheming/display_snippets/`
- Custom form snippets in `ckanext/edatosscheming/templates/scheming/form_snippets/`
- Primary language is determined from common-metadata service configuration

## Git Workflow

Main branch: `master`

Recent commits focus on CKAN dockerization updates (EDATOS-5261).
