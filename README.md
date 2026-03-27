# CKAN ISTAC
---------------------------------------------------------------

Este repositorio contiene el código fuente de las extensiones del proyecto CKAN para el ISTAC


## CKAN
---------------------------------------------------------------

Se han desarrollado las siguientes extensiones de CKAN:

- ckanext-cas: contiene el código para trabajar con un  sistema de autenticación centralizada - CAS, que devuelve las propiedades por perfil logueado .
- ckanext-edatostheme: contiene el código de la extensión creada para aplicar los estilos de EDATOS.
- ckanext-edatosscheming: contiene las definiciones de esquemas y validadores personalizados para datasets, organizaciones, grupos y showcases, extensión raíz para la internacionalización de CKAN.
- ckanext-edatosshowcase: contiene la funcionalidad de showcases, Colecciones en la aplicación.
- ckanext-gobcangroups: contiene el código para automatizar la clasificación de conjuntos de datos en categorías.
- Carpeta /etc: Contiene los ficheros de configuración para cada entorno, ademas de los ficheros comunes en todos los entornos (solo se usan en local, el despliegue utiliza los configurados en ckan-stack para cada cliente); gobcan_profile, fichero correspondiente al custom profile de DCAT para cumplir con la NTI; ckan-licenses, fichero correspondiente a las licencias configuradas en el CKAN.

### Deprecated
- ckanext-istac_theme(Deprecated): vieja versión que contiene el código de la extensión creada para modificar los estilos del CKAN, se sigue el desarrollo en ckanext-edatostheme.
- ckanext-istactranslation (Deprecated): Las traducciones se implementaron en la extensión istac_theme <s>contiene las traducciones de la extensión de theme y se implementan en esta extensión para solventar un comportamiento por defecto de CKAN que toma las traducciones siempre de la última extensión en la lista de configuración, por lo tanto deberá estar siempre en última posición en esta.</s>


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

- ckanext-cas: La configuración de CKAN debe apuntar ahora al CAS deseado y los roles/permisos del usuario son gestionados desde la gestión de permisos del sistema de autenticación centralizado a usar.
Las propiedades a configurar son las siguientes:
    - ckanext.cas.admin_property = ADMINISTRADOR
    - ckanext.cas.member_property = GESTOR
    - ckanext.cas.base_property = CATALOGO_DATOS

- Fichero db/01-edatos-publisher-import-data.sql : La propiedad FILLME corresponde a la concatenación de las propiedades de configuración de CKAN site_url y root_path .
