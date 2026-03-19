# CKAN ISTAC
---------------------------------------------------------------

Este repositorio contiene el código fuente de las extensiones del proyecto CKAN para el ISTAC


## CKAN
---------------------------------------------------------------

Se han desarrollado las siguientes extensiones de CKAN:

- ckanext-cas: contiene el código para trabajar con el CAS del ISTAC, el cual ahora consulta las propiedades y roles necesarios de éste.
- ckanext-edatostheme: contiene el código de la extensión creada para modificar los estilos del CKAN. Es la nueva versión.
- ckanext-edatosscheming: contiene las definiciones de esquemas y validadores personalizados para datasets, organizaciones, grupos y showcases.
- ckanext-edatosshowcase: contiene la funcionalidad de showcases (casos de uso asociados a datasets).
- ckanext-gobcangroups: Se ha implementado una mejora para desvincular datasets del catálogo RDF federado de GPE.
- fichero ckan-license.json: contiene las licencias necesarias para realizar el mapeado en el ckan en los procesos de federación.
- Carpeta /etc: Contiene los ficheros de configuración para cada entorno, ademas de los ficheros comunes en todos los entornos; gobcan_profile, fichero correspondiente al custom profile de DCAT; ckan-licenses, fichero correspondiente a las licencias configuradas en el CKAN.

### Deprecated
- ckanext-istac_theme(Deprecated): vieja versión que contiene el código de la extensión creada para modificar los estilos del CKAN, se sigue el desarrollo en ckanext-edatostheme.
- ckanext-istactranslation (Deprecated): Las traducciones se han vuelto a implementar en la extensión istac_theme <s>contiene las traducciones de la extensión de theme y se implementan en esta extensión para solventar un comportamiento por defecto de CKAN que toma las traducciones siempre de la última extensión en la lista de configuración, por lo tanto deberá estar siempre en última posición en esta.</s>


## Instalación y despliegue en desarrollo
---------------------------------------------------------------

> Para la guía completa de depuración y desarrollo local consultar [DEVELOPMENT.md](DEVELOPMENT.md).

### Prerrequisitos

Crear la red Docker externa (solo la primera vez):
```bash
docker network create ckan-net
```

Copiar y configurar el fichero de entorno:
```bash
cp dockerfiles/.env.bk dockerfiles/.env
# Editar dockerfiles/.env con los valores correctos (BBDD, URLs, CAS...)
```

### Generación de imágenes

```bash
docker build -f dockerfiles/ckan/Dockerfile -t docker.arte-consultores.com/istac/ckan:<version> .
docker build -f dockerfiles/ckan/Dockerfile.worker -t docker.arte-consultores.com/istac/ckan-worker:<version> .
```

### Despliegue en local

```bash
docker compose -f dockerfiles/docker-compose.yml up -d
```

## Configuración
---------------------------------------------------------------
- ckanext-gobcangroups: Es necesario para su funcionamiento que la etiqueta (Tag) exista en la base de datos o sea creado, por defecto se usa la etiqueta "Manual" pero puede ser configurada con la propiedad "ckanext.gobcangroups.flag.for.delink = Manual"

- ckanext-cas: La configuración de CKAN debe apuntar ahora al CAS del ISTAC y los roles/permisos del usuario son gestionados desde la gestión de permisos de ISTAC.
Las propiedades a configurar son las siguientes:
    - ckanext.cas.admin_property = ADMINISTRADOR
    - ckanext.cas.member_property = GESTOR
    - ckanext.cas.base_property = CATALOGO_DATOS

- Fichero db/01-edatos-publisher-import-data.sql : La propiedad FILLME corresponde a la concatenación de las propiedades de configuración de CKAN site_url y root_path .
