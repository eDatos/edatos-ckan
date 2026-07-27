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

## Adding New Extensions to Docker

When adding new CKAN extensions to the Docker environment, follow this process to ensure they are properly installed and loaded.

### Step 1: Add Extension to Plugin List

Edit `docker/ckan-docker/.env` and add the new extension(s) to the `CKAN__PLUGINS` variable:

```bash
CKAN__PLUGINS="stats image_view text_view resource_proxy datatables_view datastore gobcangroups gobcan_harvester geojson_view shp_view cas edatosscheming xloader scheming_datasets scheming_groups scheming_organizations fluent edatostheme edatosshowcase envvars"
```

**CRITICAL: Plugin Order**
- The `envvars` plugin **MUST be the last plugin** in the list
- This ensures environment variables are processed before other plugins need them
- Incorrect order will cause configuration errors like "ckan.locales_offered is required"

### Step 2: Verify Extension Files

Ensure the extension files are in the correct location:
- Custom ISTAC extensions should be in: `docker/ckan-docker/src/extensions/`
- These are mounted into the container at: `/srv/app/src/src_extensions/`

### Step 3: Rebuild and Restart Docker

To pick up new extensions, you must rebuild the Docker image without cache:

```bash
cd docker/ckan-docker

# Stop and remove containers
docker compose down

# Rebuild image without cache (forces fresh installation of all extensions)
docker compose build --no-cache ckan

# Start all services
docker compose up -d
```

**Why `--no-cache` is important:**
- Forces Docker to reinstall all Python packages
- Ensures new extensions are properly installed
- Clears any cached build layers that might be outdated

### Step 4: Verify Extensions Loaded

Check that the extensions are loaded correctly:

```bash
# Check container status
docker compose ps

# Verify extensions via API
curl -k -s https://localhost:8443/api/3/action/status_show | grep -o '"extensions":\[.*\]'

# Check logs for errors
docker compose logs ckan | grep -i error
```

### Common Issues and Solutions

#### Issue: "ckan.locales_offered is required"

**Cause:** The `edatostheme` plugin requires `ckan.locales_offered` to be set in the CKAN configuration file, but it's being read before `envvars` processes environment variables.

**Solution:**
1. Ensure `envvars` is the last plugin in `CKAN__PLUGINS`
2. If the issue persists, add the configuration directly to `ckan.ini` inside the container:

```bash
# Access the container
docker compose exec ckan bash

# Check if configuration exists
grep "ckan.locales_offered" /srv/app/ckan.ini

# If there's an empty line (e.g., "ckan.locales_offered = "), replace it
docker compose exec -u root ckan bash -c "sed -i 's/^ckan.locales_offered =$/ckan.locales_offered = es ca en/' /srv/app/ckan.ini"

# Restart CKAN
docker compose restart ckan
```

#### Issue: Redirect to `/es/null` or `/{lang}/null`

**Cause:** The `edatostheme` extension includes a JavaScript file (`i18n.js`) that automatically adds language prefixes to URLs. A bug in the redirect logic causes it to concatenate `null` when accessing the root URL without a language prefix.

**Symptoms:**
- Accessing `https://localhost:8443/` redirects to `https://localhost:8443/es/null`
- Browser shows 404 or blank page after redirect

**Root Cause:**
The JavaScript template in `ckanext-edatostheme/code_templates/i18n.js` has a bug in the redirect function:

```javascript
if (urlArray[2] === "home") {
    nuevaUrl = SITE_URL.concat(language,"/");
} else {
    nuevaUrl = SITE_URL.concat(language,"/",urlArray[2]);  // ← urlArray[2] is null/undefined
}
```

When accessing the root URL, `urlArray[2]` (the path after the language) is `null` or `undefined`, causing it to be concatenated literally as the string "null".

**Solution:**

1. Fix the template to handle empty/null values:

```bash
# Access container as root
cd docker/ckan-docker
docker compose exec -u root ckan bash

# Fix the template
sed -i '54s/if (urlArray\[2\] === "home")/if (urlArray[2] === "home" || !urlArray[2])/' \
  /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/code_templates/i18n.js

# Exit container
exit
```

2. Verify the fix:

```bash
docker compose exec ckan bash -c "grep -A3 'home' /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/code_templates/i18n.js"
```

You should see:
```javascript
if (urlArray[2] === "home" || !urlArray[2]) {
```

3. Restart CKAN to regenerate the JavaScript file:

```bash
docker compose restart ckan
```

4. Wait for CKAN to be healthy and verify:

```bash
# Check CKAN is healthy
docker compose ps | grep ckan

# Verify generated file has the fix
docker compose exec ckan bash -c "grep -A3 'home' /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/assets/js/i18n.js"
```

**Alternative: Fix in the repository**

If you have access to the source repository, fix it in `ckanext-edatostheme/ckanext/edatostheme/code_templates/i18n.js`:

```javascript
// Line 54, change from:
if (urlArray[2] === "home") {

// To:
if (urlArray[2] === "home" || !urlArray[2]) {
```

Then rebuild the Docker image:
```bash
docker compose down
docker compose build --no-cache ckan
docker compose up -d
```

**Related Configuration Issues:**

This redirect issue is often accompanied by missing locale configuration. Ensure these are set in `/srv/app/ckan.ini`:

```ini
ckan.locale_default = es
ckan.locales_offered = es ca en
ckan.root_path = /
```

If these are empty or missing, fix them:

```bash
docker compose exec -u root ckan bash -c "sed -i 's/^ckan.locales_offered =$/ckan.locales_offered = es ca en/' /srv/app/ckan.ini"
docker compose exec -u root ckan bash -c "sed -i 's/^ckan.root_path =$/ckan.root_path = \//' /srv/app/ckan.ini"
docker compose restart ckan
```

#### Issue: Extensions Not Loading After Rebuild

**Cause:** Docker is using cached layers and not reinstalling the extensions.

**Solution:**
Always use `--no-cache` flag when adding or updating extensions:

```bash
docker compose build --no-cache ckan
```

#### Issue: Configuration Changes Not Applied

**Cause:** Changes to `.env` file require container recreation.

**Solution:**
```bash
# After editing .env
docker compose down
docker compose up -d
```

The containers will be recreated with the new environment variables.

### Extension Installation in Dockerfile

The ISTAC extensions are installed in the Dockerfile during build:

```dockerfile
# Clone ckan-istac repository
RUN git clone -b EDATOS-5261_ActualizacionCKANDockerizado \
    https://git.arte-consultores.com/istac/ckan-istac.git /tmp/ckan-istac

# Move extensions to src directory
RUN mv /tmp/ckan-istac/ckanext-edatostheme src/ckanext-edatostheme && \
    mv /tmp/ckan-istac/ckanext-cas src/ckanext-cas && \
    mv /tmp/ckan-istac/ckanext-edatosscheming src/ckanext-edatosscheming && \
    mv /tmp/ckan-istac/ckanext-gobcangroups src/ckanext-gobcangroups && \
    mv /tmp/ckan-istac/ckanext-edatosshowcase src/ckanext-edatosshowcase

# Install extensions
RUN pip3 install -e src/ckanext-edatostheme && \
    pip3 install -e src/ckanext-cas && \
    pip3 install -r src/ckanext-edatosscheming/requirements.txt && \
    pip3 install -e src/ckanext-edatosscheming && \
    pip3 install -e src/ckanext-gobcangroups && \
    pip3 install -e src/ckanext-edatosshowcase
```

If you need to add a new extension, modify the Dockerfile to include the installation steps for your extension.

### Best Practices

1. **Always test extensions locally first** before adding to production
2. **Keep plugin order consistent** - envvars must be last
3. **Document any custom configurations** required by new extensions
4. **Use `--no-cache` when troubleshooting** extension loading issues
5. **Check logs immediately after startup** to catch configuration errors early
6. **Verify API response** to confirm extensions are loaded

### Example: Adding a New Extension

Let's say you want to add `ckanext-spatial`:

1. Edit `.env`:
```bash
CKAN__PLUGINS="... fluent edatostheme edatosshowcase ckanext-spatial envvars"
```

2. Rebuild:
```bash
cd docker/ckan-docker
docker compose down
docker compose build --no-cache ckan
docker compose up -d
```

3. Verify:
```bash
curl -k -s https://localhost:8443/api/3/action/status_show | grep spatial
```

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

### Legal Notice Link (per-organisation deployment)

The "Legal notice" link shown in the group/organization sidebar (`templates/group/snippets/helper.html`, `templates/organization/snippets/helper.html`) is configurable per deployment instead of hardcoded to ISTAC, since each organisation (ISTAC, IBESTAT, IECM, DREM, SEMASTAT...) runs its own CKAN instance with its own `ckan.ini`/`.env`:

```ini
ckanext.edatostheme.legal_notice_url = https://www.gobiernodecanarias.org/istac/aviso_legal.html
ckanext.edatostheme.legal_notice_label = Aviso Legal del ISTAC
```

Both default to the ISTAC values if unset (`get_legal_notice_url()` / `get_legal_notice_label()` in `ckanext-edatostheme/ckanext/edatostheme/plugin/__init__.py`), so existing ISTAC deployments keep working without changes; other organisations should set both explicitly.

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

## Code Language Convention

New code must be written entirely in English going forward — identifiers (variables, functions, classes), comments, and code-facing strings, not just one or the other. This applies across all extensions, not only new files.

Older files still contain Spanish identifiers/comments (e.g. `ckanext-edatostheme/ckanext/edatostheme/code_templates/burger_button.html`: `burgerAbierto`, `abrir_burger`, `cerrar_burger`). There is no dedicated bulk-rename effort planned — migrate opportunistically whenever such a file is touched for another reason, rather than leaving it as-is.

User-facing strings shown in the UI (labels, messages, translations) are unaffected by this convention — they follow the existing multilanguage/i18n mechanisms documented elsewhere in this file.

## Git Workflow

Main branch: `master`

Recent commits focus on CKAN dockerization updates (EDATOS-5261).

## Debug Mode and Flask-DebugToolbar

### Overview

CKAN supports Flask-DebugToolbar for development debugging. This toolbar provides:
- **Templates panel**: Shows all Jinja2 templates rendered for each request (critical for theme development)
- **SQLAlchemy queries**: Database query analysis
- **Request/Response inspection**: Headers, variables, routes
- **Performance profiling**: Timing information

**⚠️ WARNING:** Debug mode should **NEVER** be enabled in production environments.

### Prerequisites

Flask-DebugToolbar is already installed in the Docker image (`Flask-DebugToolbar 0.16.0`). If not present:

```bash
cd docker/ckan-docker
docker compose exec ckan pip install flask-debugtoolbar
```

### Step-by-Step Activation

#### 1. Enable Debug Mode in ckan.ini

```bash
cd docker/ckan-docker
docker compose exec -u root ckan sed -i 's/^debug = false/debug = true/' /srv/app/ckan.ini
```

**Verify:**
```bash
docker compose exec ckan grep "^debug" /srv/app/ckan.ini
# Should show: debug = true
```

#### 2. Verify Environment Variables (.env)

Ensure these are set in `docker/ckan-docker/.env`:

```ini
# Debug settings
DEBUG=true
CKAN__DEBUG=true
CKAN__LOGGER_CKAN__LEVEL=DEBUG
CKAN__LOGGER_CKANEXT__LEVEL=DEBUG
```

#### 3. Check Single-Process Requirement

Flask-DebugToolbar requires CKAN to run in **single-process mode**:

```bash
docker compose exec ckan ps aux | grep uwsgi
```

If you see multiple worker processes, Flask-DebugToolbar may not work correctly.

#### 4. Restart CKAN

```bash
docker compose restart ckan
```

Wait 30-60 seconds for CKAN to become healthy:

```bash
docker compose ps ckan
# STATUS should show: Up X seconds (healthy)
```

#### 5. Access the Debug Toolbar

1. Open browser and navigate to: `https://localhost:8443/`
2. Look for a **small tab/icon on the right side** of the page (may show "FLDT" or Flask logo)
3. Click the tab to expand the debug toolbar panel
4. The panel will show sections including **Templates**, **SQLAlchemy**, **Time**, **HTTP Headers**, etc.

**If the toolbar doesn't appear:**
- Hard refresh: `Ctrl + F5` (clears cache)
- Try incognito/private browsing mode
- Check browser console (`F12` → Console) for JavaScript errors
- Verify debug mode is actually enabled (see verification steps below)

### Using the Templates Panel

The **Templates** panel is the most useful for theme development:

#### Viewing Rendered Templates

1. Expand the **"Templates (XX rendered)"** section in the toolbar
2. You'll see a list like:
   ```
   package/read.html
   package/read_base.html
   package/snippets/info.html
   snippets/social.html
   base.html
   ```

#### Locating Template Files

Templates are searched in this **priority order**:

1. **Your theme** (highest priority):
   ```
   /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/
   ```

2. **Other extensions**:
   ```
   /srv/app/src/ckanext-*/ckanext/*/templates/
   ```

3. **CKAN core** (fallback):
   ```
   /srv/app/src/ckan/ckan/templates/
   ```

#### Finding Templates in the Container

```bash
# Enter container
docker compose exec ckan bash

# Find a specific template
find /srv/app/src -name "read_base.html"

# List all templates in your theme
find /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates -name "*.html" | sort

# List CKAN core templates
find /srv/app/src/ckan/ckan/templates/package -name "*.html" | head -20

# Exit container
exit
```

#### Template Override Examples

| Template shown in toolbar | Most likely location to edit |
|---------------------------|------------------------------|
| `package/read_base.html` | `/srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/package/read_base.html` |
| `package/snippets/resources.html` | Check theme first, fallback to `/srv/app/src/ckan/ckan/templates/package/snippets/resources.html` |
| `base.html` | Usually CKAN core: `/srv/app/src/ckan/ckan/templates/base.html` |

### Verification Commands

#### Check Debug Status

```bash
# Verify ckan.ini
docker compose exec ckan grep "^debug" /srv/app/ckan.ini

# Verify environment variables
docker compose exec ckan env | grep -E "DEBUG|CKAN.*DEBUG"

# Check logs for debug confirmation
docker compose logs ckan --tail 100 | grep -i "debug"
```

You should see log entries like:
```
[ckan.config.middleware] Debug mode is enabled
```

#### Test Flask-DebugToolbar Installation

```bash
docker compose exec ckan python3 -c "import flask_debugtoolbar; print('Flask-DebugToolbar installed')"
```

### Working with Templates

#### Typical Workflow

1. **Identify template** using Flask-DebugToolbar Templates panel
2. **Locate file** using find commands or the priority order above
3. **Edit template** (either on host in `src/` or inside container)
4. **Reload page** to see changes (templates auto-reload in debug mode)
5. **Verify changes** using the toolbar

#### Editing Templates from Host Machine

Templates in these directories are mounted from the host:

```
Host location:
docker/ckan-docker/src/ckanext-edatostheme/ckanext/edatostheme/templates/

Maps to container:
/srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/
```

**Changes made on the host are immediately reflected in the container** (no rebuild needed).

### Best Practices

1. **Always disable debug mode in production**
   - Set `debug = false` in ckan.ini
   - Remove `DEBUG=true` from .env

2. **Use Templates panel to understand CKAN's rendering**
   - Identify which template to override
   - Understand template inheritance chains

3. **Hot-reload in debug mode**
   - Templates auto-reload on changes
   - No container restart needed for template edits

### Quick Reference Commands

```bash
# Enable debug mode
docker compose exec -u root ckan sed -i 's/debug = false/debug = true/' /srv/app/ckan.ini
docker compose restart ckan

# Disable debug mode
docker compose exec -u root ckan sed -i 's/debug = true/debug = false/' /srv/app/ckan.ini
docker compose restart ckan

# Find template
docker compose exec ckan find /srv/app/src -name "template_name.html"

# View logs
docker compose logs ckan -f

# Check debug status
docker compose exec ckan grep "^debug" /srv/app/ckan.ini
```

## Persistent Project Knowledge

### Purpose

Maintain long-term project knowledge to improve continuity across development sessions and enable both humans and AI agents to understand the project's evolution.

After completing any significant task, evaluate whether the work introduces knowledge that should persist beyond the current conversation. If it does, update the appropriate document inside the `docs/` directory before finishing.

### What to Document

Only document information that is expected to remain valuable for future development, such as:

- Architectural decisions and their rationale.
- Design decisions and trade-offs.
- Project conventions or coding standards.
- Adopted patterns or anti-patterns.
- New dependencies and why they were introduced.
- Significant changes to the project structure.
- Reusable implementation strategies.
- Environment or configuration requirements.
- Known limitations or technical debt.
- Problems encountered and how they were resolved.
- Lessons learned that could prevent future mistakes.
- Any project-specific knowledge that would help future contributors or AI agents work more effectively.

### Documentation Guidelines

Documentation should be:

- Incremental rather than rewritten from scratch.
- Concise and focused.
- Organized by topic within the `docs/` directory.
- Easy to scan and maintain.
- Consistent with existing documentation.

Create new documents only when an appropriate one does not already exist.

### What Not to Document

Do **not** document:

- Trivial code changes.
- Temporary implementation details.
- Information already documented elsewhere.
- Experimental work that was discarded.
- Self-evident code behavior.
- Session-specific conversation history.

### Decision Rule

Before completing any task, ask yourself:

> "Will this information still be useful to a developer or AI agent in three months?"

If the answer is **yes**, persist it in the appropriate document under `docs/`.

If the answer is **no**, do not create or update documentation.

### Documentation Priority

Prefer updating existing documentation over creating new files.

When creating new documentation, choose descriptive filenames and place them in the most appropriate location within the `docs/` hierarchy.

Documentation should represent enduring project knowledge, not a changelog.