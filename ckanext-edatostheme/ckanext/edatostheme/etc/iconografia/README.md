
# Guía para crear las fonts de la extensión

Los iconos en la aplicación son cargados como fuentes, se usa un fichero CSS para realizar la codificación de ID a fuente.

1. Ir a https://icomoon.io/app
2. Subir los SVG 
3. Seleccionar Generate Fonts F
4. Descargar la fuente generada
5. Reemplazar las fuentes en la extensión, ruta: ckanext-edatos/ckanext/edatostheme/public/
6. Editar los estilos para agregar o modificar la codificación de los estilos con los ID de cada icono, ruta: ckanext-edatos/ckanext/edatostheme/assets/fonts/glyphter/css


---

El siguiente texto es el que se envía con los SVG por porte del ISTAC:
Originalmente se guardaron en el Drive de Arte:

* Enlace, https://drive.google.com/drive/folders/1sPC_c2nhhCEgcs3BXtDiLJCewXhqYQ9K?usp=share_link

* Ruta en Drive, Arte:Proyectos:ISTAC:XXXX-General:01-Imagen-corporativa:Iconos:Temas

``` Adjunto archivo comprimido, hay 2 carpetas, en una están los png y en otra los svg todos están en azul y en gris.

En cuanto a los nombres de los iconos:

La estructura sería <color>_<tema>_1_<tema>_2:
	Ej:           
		Azul_Demo_1   correspondería al Icono Azul del tema Demográficas de nivel 1
		Azul_Demo_2_Población   sería un icono Azul de nivel 2 “Población” (que pertenece Demográficas, de nivel 1)

Hay algunos que su nivel 2 se llama igual que el 1, así por ejemplo Empleo tiene 2 iconos que además son iguales

Ej:           
	Azul_Empleo_1
	Azul_Empleo_2
```
---
