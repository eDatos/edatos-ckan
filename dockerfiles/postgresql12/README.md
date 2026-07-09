# PostgreSQL 12 con restore del dump `ckan_default.dump`

## Qué es esto

Un contenedor **PostgreSQL 12** independiente y **persistente** que, en su primer arranque,
restaura automáticamente el dump `Cosas/BBDD/ckan_default.dump` y queda listo para sustituir al
servicio `db` (PostgreSQL 16) del stack CKAN dockerizado sin tocar la configuración de CKAN.

Se generó a partir de un dump con estas características (comprobadas inspeccionando el propio
fichero):

- **Formato**: custom de `pg_dump` (magic `PGDMP`), archive **v1.14**, generado originalmente con
  **PostgreSQL 12** → se restaura con `pg_restore`, no con `psql`.
- **Propietario de los objetos**: rol `catalogo-sdb-db`, que coincide exactamente con
  `CKAN_DB_USER` en `dockerfiles/.env` — el mismo usuario que ya usa CKAN.
- **Contenido**: la base de datos **principal de CKAN** (52 `TABLE DATA`: `package`, `resource`,
  `user_`, `group_`, `member`, `activity`, `revision`, `resource_view`, `dashboard`, 1 extensión).
  **No incluye el `datastore`** (se crea vacío en el arranque para que CKAN pueda iniciar).

## Estructura de archivos

```
dockerfiles/postgresql12/
├── Dockerfile                                   # postgres:12-alpine + scripts de init
├── docker-compose.pg12.yml                      # servicio standalone, red externa, volumen persistente
└── docker-entrypoint-initdb.d/
    ├── .gitattributes                           # fuerza LF en los .sh (evita roturas en Windows)
    ├── 10_create_roles_dbs.sh                    # crea rol catalogo-sdb-db, BD ckandb, BD datastore
    └── 90_restore_ckandb.sh                      # pg_restore del dump dentro de ckandb
```

Estos scripts de `docker-entrypoint-initdb.d/` solo se ejecutan **una vez**, cuando el volumen de
datos (`/var/lib/postgresql/data`) está vacío. A partir de ahí los datos son persistentes en el
volumen nombrado `pg12_data` (visible como `ckan-pg12_pg12_data` en `docker volume ls`).

El dump (~1.8 GB) **no se copia dentro de la imagen**: se monta como bind read-only desde
`Cosas/BBDD/ckan_default.dump` en `/dump/ckan_default.dump`.

## Cómo se conecta con CKAN

El servicio `db` de este compose se une a la red externa **`dockerfiles_ckan-net`** (la misma que
usa el stack principal) con el alias de red **`db`**. Por eso:

- CKAN sigue resolviendo `CKAN_SQLALCHEMY_URL=postgresql://catalogo-sdb-db:Guancha20@db:5432/ckandb`
  sin ningún cambio en `.env`.
- **Solo uno** de los dos `db` (el PG16 del compose principal o este PG12) puede estar levantado a
  la vez, porque ambos usan el mismo alias `db` y el mismo puerto `5432`.
- El volumen `pg_data` del PG16 original **no se toca** en ningún momento: parar ese servicio es
  totalmente reversible.

## Manual de uso

Todos los comandos se ejecutan desde `ckan-istac/dockerfiles/`.

### Primer arranque (con restore automático)

```powershell
# 1. Parar el PostgreSQL 16 actual para liberar el alias 'db' y el puerto 5432
docker compose stop db

# 2. Construir y levantar el PG12 (el restore se ejecuta automáticamente en este primer arranque)
docker compose -f postgresql12/docker-compose.pg12.yml up -d --build

# 3. Seguir el progreso del restore (varios minutos por los ~1.8 GB del dump)
docker compose -f postgresql12/docker-compose.pg12.yml logs -f db
#    Esperar a "database system is ready to accept connections" y a que el estado sea (healthy)

# 4. Reconectar CKAN y los workers a la nueva BD
docker compose restart ckan jobs-worker gather-consumer fetch-consumer

# 5. Esperar a que CKAN esté (healthy) y reindexar Solr con los datos del nuevo Postgres
docker compose ps ckan
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c
```

> ⚠️ Si el paso 4 provoca que `ckan` entre en bucle de reinicios (`docker compose ps ckan` no llega
> nunca a `healthy`, o un `exec` se corta con **exit code 137**), es el problema conocido descrito en
> [Solución: bucle de reinicios de `ckan` (`sed: Permission denied`)](#solución-bucle-de-reinicios-de-ckan-sed-permission-denied) más abajo.

### Día a día — levantar / bajar sin perder datos

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml stop     # baja el PG12
docker compose -f postgresql12/docker-compose.pg12.yml start    # lo vuelve a subir (sin re-restore)
```

### Bajar del todo (mantiene el volumen y los datos)

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml down
```

### Rehacer el restore desde cero (borra los datos de este PG12)

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml down -v   # elimina el volumen pg12_data
docker compose -f postgresql12/docker-compose.pg12.yml up -d --build
```

### Volver al PostgreSQL 16 original

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml down
docker compose start db
docker compose restart ckan jobs-worker gather-consumer fetch-consumer
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c
```

## Reindexar Solr tras el cambio de base de datos

Solr mantiene su **propio índice**, separado de Postgres. Cada vez que se cambia de base de datos
(PG16 ↔ PG12, o tras un `down -v` + re-restore) los `package_id` y el contenido indexado en Solr
quedan **desincronizados** con los datasets reales de la nueva BD: hay que reconstruir el índice
para que las búsquedas y el listado de datasets en CKAN reflejen los datos actuales.

```powershell
# Reindexado completo (limpia el índice y lo reconstruye desde cero con los datos de 'ckandb')
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index rebuild -c

# Comprobar que el índice está consistente con la BD (compara nº de datasets en BD vs Solr)
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index check
```

- `-c` / `--clear` — limpia el índice existente antes de reconstruirlo. **Recomendado siempre**
  tras cambiar de BD, porque los datasets indexados pueden no existir ya en la BD activa.
- Para stacks grandes puede tardar varios minutos; se puede seguir el progreso con
  `docker compose logs -f ckan` en otra terminal mientras se ejecuta.
- Si solo se han añadido/editado datasets sin cambiar de BD, basta un reindexado incremental sin
  `-c` (`ckan search-index rebuild -r`), pero **no es el caso** al conmutar entre PG16 y PG12.

## Solución: bucle de reinicios de `ckan` (`sed: Permission denied`)

Al reconectar CKAN tras el cambio de BD (paso 4) puede ocurrir que el contenedor `ckan` entre en un
**bucle de reinicios continuo** (cada 10-40 segundos) y nunca llegue a `(healthy)`. Cualquier
`docker compose exec` lanzado en ese momento (por ejemplo el `search-index rebuild` del paso 5) se
corta a mitad con **exit code 137** (`SIGKILL`) porque el contenedor se destruye y recrea mientras el
comando sigue corriendo dentro. **No es un fallo del reindexado ni de Solr**, sino un bug de
idempotencia en un script de arranque de CKAN, no relacionado con Postgres/Solr, que solo se
manifiesta la primera vez que el contenedor `ckan` se **reinicia** (no en su primer arranque desde
cero).

### Causa raíz

`dockerfiles/ckan/docker-entrypoint.d/05_setup_dcat_endpoint.sh` inserta la línea
`ckanext.dcat.catalog_endpoint` en `/srv/app/ckan.ini` en el primer arranque (usando `/tmp` como
fichero temporal, lo que no requiere permisos sobre `/srv/app/`). En cualquier arranque **posterior**
la línea ya existe, así que el script toma la rama `sed -i` directamente sobre
`/srv/app/ckan.ini` — y `sed -i` necesita crear un fichero temporal en el **directorio** del
fichero (`/srv/app/`), no solo en el fichero. El usuario del proceso CKAN (`ckan`, uid 503, grupo
`ckan-sys`) no tenía permiso de escritura sobre `/srv/app/` (`drwxr-xr-x`, propietario
`ckan-sys`), así que `sed -i` falla con:

```
sed: couldn't open temporary file /srv/app/sedXXXXXX: Permission denied
```

El script tiene `set -e`, así que ese fallo aborta el arranque de CKAN → el contenedor muere →
`restart: unless-stopped` lo relanza → vuelve a fallar en el mismo punto → bucle infinito.

### Diagnóstico

```powershell
# Confirmar el bucle (RestartCount subiendo cada pocos segundos)
docker inspect dockerfiles-ckan-1 --format 'RestartCount={{.RestartCount}} Status={{.State.Status}}'

# Ver el error exacto en los logs
docker compose logs ckan --since 5m | Select-String "Permission denied|05_setup_dcat_endpoint"
```

### Fix (aplicado en caliente, sin rebuild)

Dar permiso de escritura de grupo sobre `/srv/app/` (el usuario `ckan` pertenece al grupo
`ckan-sys`, propietario del directorio):

```powershell
docker compose exec -u root ckan chmod g+w /srv/app
```

Comprobar que el contenedor se estabiliza (deja de reiniciarse y pasa a `healthy`):

```powershell
docker inspect dockerfiles-ckan-1 --format 'RestartCount={{.RestartCount}} Status={{.State.Status}} Health={{.State.Health.Status}}'
# Repetir a los 30-60s: RestartCount no debe seguir subiendo, Health debe llegar a "healthy"
```

Este fix es **transitorio**: solo persiste mientras el contenedor actual esté vivo. Si el
contenedor `ckan` se recrea (no solo se reinicia, sino `docker compose up`/`build` de nuevo con
una imagen limpia), la condición reaparecerá en su segundo arranque. La corrección definitiva
(pendiente, fuera del alcance de este documento) es ajustar el permiso del directorio en el
`Dockerfile` de `ckan`, o hacer que `05_setup_dcat_endpoint.sh` escriba siempre vía `/tmp` (como ya
hace la rama `else` del propio script) en lugar de usar `sed -i` in situ.

## Verificación

```powershell
# Versión del motor (debe ser PostgreSQL 12)
docker compose -f postgresql12/docker-compose.pg12.yml exec db psql -U postgres -c "SELECT version();"

# Tablas restauradas y su propietario (debe ser catalogo-sdb-db)
docker compose -f postgresql12/docker-compose.pg12.yml exec db psql -U postgres -d ckandb -c "\dt"

# Datos presentes
docker compose -f postgresql12/docker-compose.pg12.yml exec db psql -U postgres -d ckandb -c "SELECT count(*) FROM package;"

# CKAN respondiendo con los datos restaurados
curl.exe -k -s https://localhost:8443/api/3/action/status_show
curl.exe -k -s "https://localhost:8443/api/3/action/package_list"

# El índice de Solr coincide con los datasets de la BD (tras el rebuild -c)
docker compose exec ckan ckan -c /srv/app/ckan.ini search-index check

# Logs de CKAN sin errores de conexión tras el restart
docker compose logs ckan --tail 80 | Select-String -Pattern "error","OperationalError" -CaseSensitive:$false
```

## Notas y riesgos

- **Warnings de `pg_restore`**: mensajes sobre `COMMENT ON EXTENSION` o `GRANT` son benignos; el
  script `90_restore_ckandb.sh` los tolera y no aborta el arranque por ellos.
- **Tiempo del primer arranque**: el restore tarda varios minutos; no reconectar CKAN hasta que el
  contenedor esté en estado `(healthy)`.
- **Healthcheck**: usa `CMD-SHELL` con `$$POSTGRES_USER`/`$$POSTGRES_DB` (escapado) porque estas
  variables las resuelve el propio contenedor a partir de `env_file`, no Compose al parsear el
  YAML — al invocar con `-f` desde un subdirectorio, Compose no ve el `.env` de `dockerfiles/` para
  la sustitución a nivel de fichero.
- **Compatibilidad de formato**: al ser un dump generado con PostgreSQL 12 restaurado sobre
  PostgreSQL 12, no hay problemas de compatibilidad de versión.

## Solución: `network ... not found` al arrancar `ckan-pg12-db-1`

Síntoma al hacer `start` o `up -d`:

```
Error response from daemon: failed to set up container networking: network <id> not found
```

**Causa**: la red externa `dockerfiles_ckan-net` fue borrada y recreada (por ejemplo con un
`docker compose down` sobre el stack principal, que por defecto también elimina las redes que
crea). Al recrearse, la red obtiene un **ID nuevo**, pero el contenedor `ckan-pg12-db-1` guarda
internamente el ID **antiguo** con el que se conectó la primera vez — y ese ID ya no existe. El
contenedor queda "huérfano" de red aunque exista una red con el mismo *nombre*.

**Fix** (no borra datos; solo recrea el contenedor, el volumen `pg12_data` no se toca):

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml down   # borra solo el contenedor
docker compose -f postgresql12/docker-compose.pg12.yml up -d  # lo recrea enganchado a la red actual
```

Verificar que no ha vuelto a ejecutar el restore (debe decir "Skipping initialization", no
"database files were not found"):

```powershell
docker compose -f postgresql12/docker-compose.pg12.yml logs db --tail 15
```

**Para evitar que vuelva a pasar**: usar siempre `docker compose stop`/`start` sobre el stack
principal (`dockerfiles/docker-compose.yml`) en lugar de `down`/`up` cuando el objetivo sea solo
parar/reanudar servicios — `down` destruye la red compartida y descoloca a cualquier contenedor
externo (como este PG12) que dependa de ella.
