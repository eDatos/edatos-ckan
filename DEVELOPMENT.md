
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

### Troubleshooting

#### Problem: Toolbar Not Appearing

**Cause 1: Debug mode not actually enabled**

```bash
# Check actual debug value (not commented out)
docker compose exec ckan grep "^debug" /srv/app/ckan.ini

# Should show: debug = true
# If shows: debug = false, then fix it:
docker compose exec -u root ckan sed -i 's/^debug = false/debug = true/' /srv/app/ckan.ini
docker compose restart ckan
```

**Cause 2: JavaScript errors in browser**

1. Open browser DevTools (`F12`)
2. Go to **Console** tab
3. Look for errors related to Flask or DebugToolbar

**Cause 3: Multi-process mode**

Flask-DebugToolbar doesn't work with multiple WSGI workers. Check uWSGI configuration:
```bash
docker compose exec ckan grep -E "processes|workers" /srv/app/ckan.ini
```

#### Problem: Templates Panel is Empty

This means no Jinja2 templates were rendered. Try navigating to a dataset page: `/dataset/{dataset-name}`

#### Problem: Redirect Issues (localhost → IP)

If Flask-DebugToolbar redirects from `localhost` to `192.168.10.110`, check `siteURL` in theme config:

```bash
docker compose exec ckan cat /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json | grep siteURL
```

Should be:
```json
"siteURL": "https://localhost:8443/"
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
