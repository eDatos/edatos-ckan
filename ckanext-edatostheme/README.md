[![Tests](https://github.com//ckanext-edatostheme/workflows/Tests/badge.svg?branch=main)](https://github.com//ckanext-edatostheme/actions)

# ckanext-edatostheme

Extensión que contiene la capa de estilos del portal de datos abiertos 



## Requirements

Extensión creada para la versión 2.9.0 de CKAN y superiores



## Installation


Para instalar la extensión ckanext-edatostheme:

1. Activar el entorno Python del CKAN estando como el usuario ckan::

     . default/bin/activate

2. Instalar la extensión ckanext-edatostheme en el entorno virtual de Python::

     pip install ckanext-edatostheme

Es recomendable realizar la instalación explicada en los pasos ``Development installation``.

3. Añadir la extensión en la lista de plugins de CKAN  en el fichero de configuración
   ``/servers/opendata/ckan/default/development.ini`` en la propiedad ``ckan.plugins`` añadir ``edatostheme``


4. Rellenar las URL y propiedades de configuración del fichero ``/ckanext/edatostheme/etc/config.json``

5. Modificar los permisos de los ficheros header y footer

     * chmod 777 chmod 777 /servers/catalogo/ckan/default/src/ckanext-edatostheme/ckanext/edatostheme/templates/header.html
     * chmod 777 chmod 777 /servers/catalogo/ckan/default/src/ckanext-edatostheme/ckanext/edatostheme/templates/footer.html


6. La propiedad ``ckanext.gobcangroups.flag.for.delink`` de la extensión ckanext-gobcangroups es usada para ocultar de las plantillas las etiquetas para los datasets desvinculados del GPE.

7. Reiniciar el servicio Apache estando como root::

     systemctl restart httpd

---

* NOTA:

Para visualizar los posibles cambios efectuados en componentes-apps, en el header y en el footer, es necesario realizar una reload del servicio Apache, ya que los recursos necesarios son consultados, obtenidos y almacenados únicamente en la fase de arranque del CKAN:


     systemctl reload httpd 

## Config settings

Ver el manual de instalación para obtener las configuraciones.


## Developer installation

Para instalar la extensión ckanext-edatostheme en Desarrollo hacer lo siguiente 
estando dentro del entorno virtual de Python::

     Subir el directorio al servidor en la ruta ``/servers/catalogo/ckan/default/src/``
     cd ckanext-edatostheme
     pip install -r dev-requirements.txt
     pip install -e .