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

- Se debe de modificar la configuración para las bases de datos, las propiedades son:
  - `CKAN_SQLALCHEMY_URL`
  - `CKAN_DATASTORE_WRITE_URL`
  - `CKAN_DATASTORE_READ_URL`
  - `CKANEXT__XLOADER__JOBS_DB__URI`

- En `dockerfiles/.env` se deben actualizar lo siguiente:
  - `CKAN_SITE_URL`
  - `CKANEXT__PAGE_URL`
  - `CKANEXT__DCAT__BASE_URI`
  - `CKANEXT__CAS__APPLICATION_URL`

- Comprobar en la configuración JSON de la extensión **ckanext-edatostheme** (`dockerfiles/src/ckanext-edatostheme/ckanext/edatostheme/etc/config.json`), la propiedad:
  - `siteURL` — Debe coincidir con `CKAN_SITE_URL` (ej: `https://192.168.10.110:8443/`)

- Comprobar las rutas de los endpoints en la configuración JSON de las extensiones (`config.json` de edatostheme y edatosscheming) por si han cambiado.

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

| Plantilla mostrada en la barra    | Ubicación más probable para editar                                                                     |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `package/read_base.html`          | `/srv/app/src/ckanext-edatostheme/ckanext/edatostheme/templates/package/read_base.html`                |
| `package/snippets/resources.html` | Comprobar primero el tema, si no en `/srv/app/src/ckan/ckan/templates/package/snippets/resources.html` |
| `base.html`                       | Normalmente CKAN core: `/srv/app/src/ckan/ckan/templates/base.html`                                    |

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

## Base de datos PostgreSQL 12 con restore de un dump (`ckan_default.dump`)

### Descripción general

Para trabajar con una copia de datos real (por ejemplo un dump `ckan_default.dump` exportado de
otro entorno), existe un stack Docker independiente en `dockerfiles/postgresql12/` que levanta un
**PostgreSQL 12 persistente** y restaura el dump automáticamente en su primer arranque, sustituyendo
al servicio `db` (PostgreSQL 16) sin tocar la configuración de CKAN.

El contenedor se une a la misma red externa que usa el stack principal
(`dockerfiles_ckan-net`) con el alias `db`, así que `CKAN_SQLALCHEMY_URL` y el resto de variables de
conexión en `.env` siguen funcionando sin cambios. Solo uno de los dos `db` (el PG16 original o
este PG12) puede estar levantado a la vez, ya que comparten alias de red y puerto `5432`.

Documentación completa (manual paso a paso, verificación, notas de diseño y solución de
problemas): [`dockerfiles/postgresql12/README.md`](dockerfiles/postgresql12/README.md).

### Requisito

El dump a restaurar debe existir en `Cosas/BBDD/ckan_default.dump` (ruta relativa usada por
`docker-compose.pg12.yml`). Es un dump en formato custom de `pg_dump` (`pg_restore`), no un SQL
plano.

### Primer arranque (con restore automático)

```powershell
cd dockerfiles

# 1. Parar el PostgreSQL 16 actual para liberar el alias 'db' y el puerto 5432
docker compose stop db

# 2. Construir y levantar el PG12 (el restore se ejecuta automáticamente, tarda varios minutos)
docker compose -f postgresql12/docker-compose.pg12.yml up -d --build

# 3. Seguir el progreso hasta ver "database system is ready to accept connections" y (healthy)
docker compose -f postgresql12/docker-compose.pg12.yml logs -f db

# 4. Reconectar CKAN y los workers a la nueva BD
docker compose restart ckan jobs-worker gather-consumer fetch-consumer

# 5. Reindexar Solr: su índice queda desincronizado al cambiar de base de datos
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c
```

### Reindexar Solr tras el cambio de base de datos

Solr mantiene su **propio índice**, separado de Postgres. Al conmutar entre el PG16 original y este
PG12 (o tras rehacer el restore) los datasets indexados quedan desincronizados con la BD activa:
hay que reconstruir el índice para que las búsquedas y los listados de CKAN reflejen los datos
reales. Detalle completo en
[`dockerfiles/postgresql12/README.md`](dockerfiles/postgresql12/README.md#reindexar-solr-tras-el-cambio-de-base-de-datos).

```bash
# Reindexado completo (limpia el índice y lo reconstruye con los datos de la BD activa)
docker compose -f dockerfiles/docker-compose.yml exec ckan ckan -c /srv/app/ckan.ini search-index rebuild

# Comprobar consistencia entre BD y Solr
docker compose -f dockerfiles/docker-compose.yml exec ckan ckan -c /srv/app/ckan.ini search-index check
```

### Problema conocido: `ckan` en bucle de reinicios al reconectar tras el cambio de BD

Al ejecutar el paso 4 (`docker compose restart ckan ...`) el contenedor `ckan` puede entrar en un
**bucle de reinicios** (cada 10-40s, sin llegar nunca a `healthy`). Si esto ocurre, cualquier
`docker compose exec` en curso —incluido el `search-index rebuild` del paso 5— se corta con
**exit code 137** a mitad de la reindexación.

**No es un problema de Solr ni del cambio de base de datos**: es un bug de idempotencia en
`dockerfiles/ckan/docker-entrypoint.d/05_setup_dcat_endpoint.sh`. La primera vez que arranca CKAN,
el script añade una línea a `/srv/app/ckan.ini` escribiendo vía `/tmp` (sin problema). En cualquier
arranque **posterior** (como el que provoca este `restart`) la línea ya existe y el script usa
`sed -i` directamente sobre `/srv/app/ckan.ini`, lo que requiere permiso de escritura sobre el
**directorio** `/srv/app/` — permiso que el usuario `ckan` no tiene (`sed: couldn't open temporary
file /srv/app/sedXXXXXX: Permission denied`). Al tener `set -e`, ese fallo aborta el arranque y el
contenedor se reinicia en bucle.

**Fix en caliente** (persiste solo mientras el contenedor esté vivo; se pierde si se recrea desde
cero):

```powershell
docker compose -f dockerfiles/docker-compose.yml exec -u root ckan chmod g+w /srv/app

# Confirmar que se estabiliza (RestartCount deja de subir, Health llega a "healthy")
docker inspect dockerfiles-ckan-1 --format 'RestartCount={{.RestartCount}} Health={{.State.Health.Status}}'
```

Corrección definitiva pendiente (no aplicada, fuera del alcance de este documento): ajustar el
permiso de `/srv/app/` en el `Dockerfile` de `ckan`, o hacer que `05_setup_dcat_endpoint.sh` escriba
siempre vía `/tmp` en lugar de `sed -i` in situ. Detalle completo del diagnóstico en
[`dockerfiles/postgresql12/README.md`](dockerfiles/postgresql12/README.md#solución-bucle-de-reinicios-de-ckan-sed-permission-denied).

### Referencia rápida de comandos

```bash
# Día a día: bajar / subir sin perder datos
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml stop
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml start

# Bajar del todo manteniendo el volumen persistente
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml down

# Rehacer el restore desde cero (borra los datos de este PG12)
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml down -v
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml up -d --build

# Volver al PostgreSQL 16 original
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml down
docker compose -f dockerfiles/docker-compose.yml start db
docker compose -f dockerfiles/docker-compose.yml restart ckan jobs-worker gather-consumer fetch-consumer
docker compose -f dockerfiles/docker-compose.yml exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c

# Verificar versión, tablas restauradas y datos
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml exec db psql -U postgres -c "SELECT version();"
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml exec db psql -U postgres -d ckandb -c "\dt"
docker compose -f dockerfiles/postgresql12/docker-compose.pg12.yml exec db psql -U postgres -d ckandb -c "SELECT count(*) FROM package;"

# Reindexar Solr (obligatorio tras cualquier cambio de base de datos)
docker compose -f dockerfiles/docker-compose.yml exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c
```
