# Dumps de PostgreSQL

En esta carpeta se deben colocar los **dumps de PostgreSQL** que se quieran restaurar con el
stack de desarrollo `dockerfiles/postgresql18/` (ver
[`dockerfiles/postgresql18/README.md`](../../dockerfiles/postgresql18/README.md) para el
procedimiento completo de restore, arranque, parada, reindexado de Solr, etc.).

## Formato esperado

Un dump en **formato custom de `pg_dump`** (el que se restaura con `pg_restore`, no un `.sql`
plano). Se puede comprobar con:

```bash
head -c 5 nombre_del_dump.dump
# Debe empezar por "PGDMP"
```

## Nombre esperado

Por defecto, `docker-compose.pg18.yml` monta el fichero:

```
ckan_default.dump
```

Si se quiere usar un dump con otro nombre, hay que actualizar la ruta del volumen en
`dockerfiles/postgresql18/docker-compose.pg18.yml`:

```yaml
volumes:
  - ../../herramientas/bbdd/<tu_dump>.dump:/dump/ckan_default.dump:ro
```

## Control de versiones

El contenido de esta carpeta (salvo este `README.md`) está **excluido de git** (`.gitignore` del
proyecto) porque los dumps suelen pesar varios GB. Cada persona/entorno debe colocar aquí su
propia copia del dump a restaurar; no se versiona ni se comparte por git.
