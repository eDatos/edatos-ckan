
## Modo Debug y Flask-DebugToolbar

### Descripción general

CKAN soporta Flask-DebugToolbar para depuración en desarrollo. Esta barra de herramientas proporciona:
- **Panel de plantillas**: Muestra todas las plantillas Jinja2 renderizadas en cada petición (fundamental para el desarrollo del tema)
- **Consultas SQLAlchemy**: Análisis de consultas a la base de datos
- **Inspección de peticiones/respuestas**: Cabeceras, variables, rutas
- **Perfilado de rendimiento**: Información de tiempos

**⚠️ ADVERTENCIA:** El modo debug **NUNCA** debe habilitarse en entornos de producción.

### Prerrequisitos

#### Conexión VPN

**Es obligatorio estar conectado a la VPN corporativa** para que los contenedores puedan acceder a los servicios internos (base de datos, CAS, cmetadata, etc.).

#### Base de datos externa

Si se quiere usar una base de datos PostgreSQL externa (host: `ckan-docker-db-1` o `estadisticas.arte.internal`). Verificar que el host de la BBDD sea accesible desde los contenedores y actualizar la configuración de BBDD en .env .

#### Configuración del .env

* Se debe de modificar la configuración para las bases de datos, las propiedades son:
  - `CKAN_SQLALCHEMY_URL`
  - `CKAN_DATASTORE_WRITE_URL`
  - `CKAN_DATASTORE_READ_URL`
  - `CKANEXT__XLOADER__JOBS_DB__URI`

* En `dockerfiles/.env` se deben actualizar lo siguiente:
  - `CKAN_SITE_URL`
  - `CKANEXT__PAGE_URL`
  - `CKANEXT__DCAT__BASE_URI`
  - `CKANEXT__CAS__APPLICATION_URL`

* Comprobar en la configuración JSON de la extensión **ckanext-edatostheme** (`dockerfiles/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json`), la propiedad:
  - `siteURL` — Debe coincidir con `CKAN_SITE_URL` (ej: `https://192.168.10.110:8443/`)

* Comprobar las rutas de los endpoints en la configuración JSON de las extensiones (`config.json` de edatostheme y edatosscheming) por si han cambiado.


Flask-DebugToolbar ya viene instalado en la imagen Docker (`Flask-DebugToolbar 0.16.0`). Si no está presente:

```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan pip install flask-debugtoolbar
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan apt install vim -y
```

### Activación paso a paso

#### 1. Habilitar el modo debug en ckan.ini

```bash
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan sed -i 's/^debug = false/debug = true/' /srv/app/ckan.ini
```

**Verificar:**
```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan grep "^debug" /srv/app/ckan.ini
# Debería mostrar: debug = true
```

#### 2. Verificar las variables de entorno (.env)

Asegurarse de que estas variables estén configuradas en `dockerfiles/.env`:

```ini
# Configuración de debug
DEBUG=true
CKAN__DEBUG=true
CKAN__LOGGER_CKAN__LEVEL=DEBUG
CKAN__LOGGER_CKANEXT__LEVEL=DEBUG
```

#### 3. Requisito de proceso único

Flask-DebugToolbar requiere que CKAN se ejecute en **modo de proceso único**:

```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan ps aux | grep uwsgi
```

Si se ven múltiples procesos worker, Flask-DebugToolbar podría no funcionar correctamente.

#### 4. Reiniciar CKAN

```bash
docker compose -f dockerfiles/docker-compose.yml restart ckan
```

Esperar 30-60 segundos hasta que CKAN esté sano:

```bash
docker compose -f dockerfiles/docker-compose.yml ps ckan
# El STATUS debería mostrar: Up X seconds (healthy)
```

#### 5. Acceder a la barra de depuración

1. Abrir el navegador y navegar a: `https://localhost:8443/`
2. Buscar una **pestaña/icono pequeño en el lado derecho** de la página (puede mostrar "FLDT" o el logo de Flask)
3. Hacer clic en la pestaña para expandir el panel de la barra de depuración
4. El panel mostrará secciones incluyendo **Templates**, **SQLAlchemy**, **Time**, **HTTP Headers**, etc.

**Si la barra no aparece:**
- Forzar recarga: `Ctrl + F5` (limpia la caché)
- Probar en modo incógnito/privado del navegador
- Revisar la consola del navegador (`F12` → Consola) en busca de errores JavaScript
- Verificar que el modo debug esté realmente habilitado (ver pasos de verificación más abajo)

### Uso del panel de plantillas

El panel de **Templates** es el más útil para el desarrollo del tema:

#### Ver las plantillas renderizadas

1. Expandir la sección **"Templates (XX rendered)"** en la barra
2. Se verá una lista como:
   ```
   package/read.html
   package/read_base.html
   package/snippets/info.html
   snippets/social.html
   base.html
   ```

#### Localizar archivos de plantillas

Las plantillas se buscan en este **orden de prioridad** (el orden de las extensiones configuradas importa):

1. **Tu tema** (máxima prioridad):
   ```
   /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/
   ```

2. **Otras extensiones**:
   ```
   /srv/app/src/ckanext-*/ckanext/*/templates/
   ```

3. **CKAN core** (última opción):
   ```
   /srv/app/src/ckan/ckan/templates/
   ```

#### Buscar plantillas en el contenedor

```bash
# Entrar al contenedor
docker compose -f dockerfiles/docker-compose.yml exec ckan bash

# Buscar una plantilla específica
find /srv/app/src -name "read_base.html"

# Listar todas las plantillas del tema
find /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates -name "*.html" | sort

# Listar plantillas del core de CKAN
find /srv/app/src/ckan/ckan/templates/package -name "*.html" | head -20

# Salir del contenedor
exit
```

#### Ejemplos de sobreescritura de plantillas

| Plantilla mostrada en la barra | Ubicación más probable para editar |
|--------------------------------|------------------------------------|
| `package/read_base.html` | `/srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/package/read_base.html` |
| `package/snippets/resources.html` | Comprobar primero el tema, si no en `/srv/app/src/ckan/ckan/templates/package/snippets/resources.html` |
| `base.html` | Normalmente CKAN core: `/srv/app/src/ckan/ckan/templates/base.html` |

### Comandos de verificación

#### Comprobar el estado del debug

```bash
# Verificar ckan.ini
docker compose -f dockerfiles/docker-compose.yml exec ckan grep "^debug" /srv/app/ckan.ini

# Verificar variables de entorno
docker compose -f dockerfiles/docker-compose.yml exec ckan env | grep -E "DEBUG|CKAN.*DEBUG"

# Comprobar en los logs la confirmación del debug
docker compose -f dockerfiles/docker-compose.yml logs ckan --tail 100 | grep -i "debug"
```

Deberían verse entradas en los logs como:
```
[ckan.config.middleware] Debug mode is enabled
```

#### Comprobar la instalación de Flask-DebugToolbar

```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan python3 -c "import flask_debugtoolbar; print('Flask-DebugToolbar instalado')"
```

### Resolución de problemas

#### Problema: La barra no aparece

**Causa 1: El modo debug no está realmente habilitado**

```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan pip install flask-debugtoolbar
# Comprobar el valor real de debug (no comentado)
docker compose -f dockerfiles/docker-compose.yml exec ckan grep "^debug" /srv/app/ckan.ini

# Debería mostrar: debug = true
# Si muestra: debug = false, corregirlo:
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan sed -i 's/^debug = false/debug = true/' /srv/app/ckan.ini
docker compose -f dockerfiles/docker-compose.yml restart ckan
```

**Causa 2: Errores JavaScript en el navegador**

1. Abrir las herramientas de desarrollo del navegador (`F12`)
2. Ir a la pestaña **Consola**
3. Buscar errores relacionados con Flask o DebugToolbar

**Causa 3: Modo multiproceso**

Flask-DebugToolbar no funciona con múltiples workers WSGI. Comprobar la configuración de uWSGI:
```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan grep -E "processes|workers" /srv/app/ckan.ini
```

#### Problema: El panel de plantillas está vacío

Esto significa que no se renderizaron plantillas Jinja2. Intentar navegar a una página de dataset: `/dataset/{nombre-del-dataset}`

#### Problema: Redirecciones (localhost → IP)

Si Flask-DebugToolbar redirige de `localhost` a `192.168.10.110`, comprobar `siteURL` en la configuración del tema:

```bash
docker compose -f dockerfiles/docker-compose.yml exec ckan cat /srv/app/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json | grep siteURL
```

Debe coincidir con el valor de `CKAN_SITE_URL` en `dockerfiles/.env`, por ejemplo:
```json
"siteURL": "https://192.168.10.110:8443/"
```

### Trabajo con plantillas

#### Flujo de trabajo típico

1. **Identificar la plantilla** usando el panel de Templates de Flask-DebugToolbar
2. **Localizar el archivo** usando los comandos find o el orden de prioridad anterior
3. **Editar la plantilla** (en el host en `src/` o dentro del contenedor)
4. **Recargar la página** para ver los cambios (las plantillas se recargan automáticamente en modo debug)
5. **Verificar los cambios** usando la barra de depuración

#### Editar configuraciones desde la máquina host

Las configuraciones JSON de las extensiones están montadas como volúmenes desde el host:

```
Ubicación en el host:
dockerfiles/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json
dockerfiles/src/ckanext-edatosscheming/ckanext/edatosscheming/etc/config.json

Ubicación en el contenedor:
/srv/app/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json
/srv/app/src/ckanext-edatosscheming/ckanext/edatosscheming/etc/config.json
```

**Los cambios en estos ficheros de configuración se reflejan inmediatamente en el contenedor** (no requiere rebuild).

**Nota:** Los templates HTML **no están montados** como volúmenes. Para modificar templates se debe entrar al contenedor o reconstruir la imagen.

### Buenas prácticas

1. **Siempre deshabilitar el modo debug en producción**
   - Establecer `debug = false` en ckan.ini
   - Eliminar `DEBUG=true` del .env

2. **Usar el panel de Templates para entender el renderizado de CKAN**
   - Identificar qué plantilla sobreescribir
   - Entender las cadenas de herencia de plantillas

3. **Recarga en caliente en modo debug**
   - Las plantillas se recargan automáticamente con los cambios
   - No se necesita reiniciar el contenedor para ediciones de plantillas

### Referencia rápida de comandos

```bash
# Habilitar modo debug
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan sed -i 's/debug = false/debug = true/' /srv/app/ckan.ini
docker compose -f dockerfiles/docker-compose.yml restart ckan

# Deshabilitar modo debug
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan sed -i 's/debug = true/debug = false/' /srv/app/ckan.ini
docker compose -f dockerfiles/docker-compose.yml restart ckan

# Buscar plantilla
docker compose -f dockerfiles/docker-compose.yml exec ckan find /srv/app/src -name "nombre_plantilla.html"

# Ver logs
docker compose -f dockerfiles/docker-compose.yml logs ckan -f

# Comprobar estado del debug
docker compose -f dockerfiles/docker-compose.yml exec ckan grep "^debug" /srv/app/ckan.ini
```
