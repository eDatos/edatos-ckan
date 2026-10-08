# UPGRADE - Proceso de actualización entre versiones

_Para actualizar de una versión a otra es suficiente con desplegar la imagen Docker de la nueva versión. El siguiente listado presenta aquellos cambios de versión en los que no es suficiente con actualizar y que requieren por parte del instalador tener más cosas en cuenta. Si el cambio de versión engloba varios cambios de versión del listado, estos han de ejecutarse en orden de más antiguo a más reciente._

_De esta forma, si tuviéramos una instalación en una versión **A.B.C** y quisiéramos actualizar a una versión posterior **X.Y.Z** para la cual existan versiones anteriores que incluyan cambios listados en este documento, se deberá realizar la actualización pasando por todas estas versiones antes de poder llegar a la versión deseada._

_EJEMPLO: Queremos actualizar desde la versión 1.0.0 a la 3.0.0 y existe un cambio en la base de datos en la actualización de la versión 1.0.0 a la 2.0.0._

_Se deberá realizar primero la actualización de la versión 1.0.0 a la 2.0.0 y luego desde la 2.0.0 a la 3.0.0_

_Los scripts SQL se ejecutan manualmente contra la base de datos de CKAN, previa copia de seguridad. No actualizan el índice de Solr, por lo que después hay que reindexar con `ckan -c /srv/app/ckan.ini search-index rebuild`. Las variables de entorno se configuran en el `.env` de cada cliente y entorno del proyecto ckan-stack._

## 4.2.0 a 4.3.0-SNAPSHOT

- Los siguientes scripts SQL de normalización de etiquetas ya se han ejecutado en PRO ISTAC y **no deben ejecutarse en ningún otro entorno**. Se incluyen solo como registro de los cambios realizados en los datos:

```
etc/config/changes-from-release/4.2.0/01-20261005-normalizacion_tags_package_extra.sql
etc/config/changes-from-release/4.2.0/02-20261005-normalizacion_titlecase_38.sql
```

- En PRO ISTAC, se realiza el reindexado de Solr para que el buscador muestre las etiquetas corregidas.

## 4.0.0 a 4.1.0

- Se cambian las siguientes variables de entorno. Deben fijarse explícitamente a `false`, ya que CKAN las activa por defecto:
  - CKAN**AUTH**PUBLIC_USER_DETAILS=false
  - CKAN**AUTH**PUBLIC_ACTIVITY_STREAM_DETAIL=false
- La variable `CKANEXT__EDATOSTHEME__LEGAL_NOTICE_LICENSE_ID` debe estar definida, en caso de que no lo estuviese (Ejemplo: istac-aviso-legal). Su valor debe existir como id en el `licenses.json` del cliente; si no, no se muestra el enlace al aviso legal.
- La cabecera y el pie externos pasan a cargarse desde el navegador. Los endpoints del servicio de metadatos deben ser accesibles desde el navegador del usuario y permitir CORS para el dominio del catálogo.
- Deja de ser necesario el `chmod 777` sobre `templates/header.html` y `templates/footer.html`.
- Es necesario ejecutar los siguientes scripts SQL de corrección de temáticas (`dcat:theme`). Solo aplican a la base de datos de ISTAC; en otros entornos no modifican nada:

```
etc/config/changes-from-release/4.0.0/01-20260824-migracion_tematicas_i18n_pendientes.sql
etc/config/changes-from-release/4.0.0/02-20260824-migracion_tematicas_i18n_pkg_194d1360.sql
```

- Los siguientes scripts SQL son de detección (solo lectura). Tras la corrección, `03`, `05` y `06` deben devolver 0 filas. Si en otro entorno devuelven filas, hay que generar la corrección equivalente para ese entorno:

```
etc/config/changes-from-release/4.0.0/03-20260824-deteccion_tematicas_mal_formadas.sql
etc/config/changes-from-release/4.0.0/04-20260824-deteccion_datasets_multiples_tematicas.sql
etc/config/changes-from-release/4.0.0/05-20260824-deteccion_multiples_tematicas_sin_corregir.sql
etc/config/changes-from-release/4.0.0/06-20260824-deteccion_multiples_tematicas_separadores.sql
```

- Los datasets que devuelva el siguiente script de detección deben migrarse con el script `add_extras_i18n_mod.py` (ver 1.0.0 a 1.1.0):

```
etc/config/changes-from-release/4.0.0/07-20260902-deteccion_datasets_sin_traducciones.sql
```

- Tras los scripts es necesario reindexar Solr y esperar el ciclo de federación con datos.gob.es.

## 1.0.0 a 1.1.0

- Se migran los datos al modelo multilingüe. Deben estar activos los plugins `scheming_datasets`, `scheming_groups`, `scheming_organizations`, `fluent` y `edatosscheming` en `CKAN__PLUGINS`, con `envvars` en última posición. También deben estar definidas `CKAN__LOCALE_DEFAULT` y `CKAN__LOCALES_OFFERED`.
- Es necesario ejecutar los siguientes scripts SQL. `02` solo aplica a la base de datos de ISTAC, y `03` es la verificación de `02` (debe devolver 0 filas):

```
etc/config/changes-from-release/1.0.0/db/ckan/postgresql/01-20260622-migracion_etiquetas_i18n.sql
etc/config/changes-from-release/1.0.0/db/ckan/postgresql/02-20260622-migracion_tematicas_i18n.sql
etc/config/changes-from-release/1.0.0/db/ckan/postgresql/03-20260622-verificacion_tematicas_i18n.sql
```

- Los datasets que sigan sin traducciones se migran a través de la API con el siguiente script, rellenando antes `CKAN_URL` y `API_KEY` (token de un sysadmin). El script sobrescribe las traducciones existentes y los extras libres, así que solo debe usarse con datasets que aún no se hayan migrado, y probarse antes en PRE:

```
etc/config/changes-from-release/1.0.0/scripts/add_extras_i18n_mod.py
```

- Tras los scripts es necesario reindexar Solr completo.
