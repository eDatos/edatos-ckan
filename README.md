# CKAN ISTAC
---------------------------------------------------------------

Este repositorio contiene el código fuente de las extensiones del proyecto CKAN para el ISTAC


## CKAN
---------------------------------------------------------------

Se han desarrollado las siguientes extensiones de CKAN:

- ckanext-cas: contiene el código para trabajar con el CAS del ISTAC, el cual ahora consulta las propiedades y roles necesarios de éste. 

- ckanext-istac_theme: contiene el código de la extensión creada para modificar los estilos del CKAN
- fichero ckan-license.json: contiene las licencias necesarias para realizar el mapeado en el ckan en los procesos de federación.
- ckanext-istactranslation (Deprecated): Las traducciones se han vuelto a implementar en la extensión istac_theme <s>contiene las traducciones de la extensión de theme y se implementan en esta extensión para solventar un comportamiento por defecto de CKAN que toma las traducciones siempre de la última extensión en la lista de configuración, por lo tanto deberá estar siempre en última posición en esta.</s>
- ckanext-gobcangroups: Se ha implementado una mejora para desvincular datasets del catálogo RDF federado de GPE
- Carpeta etc: Contiene los ficheros de configuración para cada entorno, ademas de los ficheros comunes en todos los entornos; gobcan_profile, fichero correspondiente al custom profile de DCAT; ckan-licenses, fichero correspondiente a las licencias configuradas en el CKAN.

## Instalación
---------------------------------------------------------------

El proceso de instalación y configuración de las extensiones y ficheros de configuración se explica en los manuales de configuración del proyecto.

## Configuración
---------------------------------------------------------------
- ckanext-gobcangroups: Es necesario para su funcionamiento que la etiqueta (Tag) exista en la base de datos o sea creado, por defecto se usa la etiqueta "Manual" pero puede ser configurada con la propiedad "ckanext.gobcangroups.flag.for.delink = Manual"

- ckanext-cas: La configuración de CKAN debe apuntar ahora al CAS del ISTAC y los roles/permisos del usuario son gestionados desde la gestión de permisos de ISTAC.
Las propiedades a configurar son las siguientes:
    - ckanext.cas.admin_property = ADMINISTRADOR
    - ckanext.cas.member_property = GESTOR
    - ckanext.cas.base_property = CATALOGO_DATOS
