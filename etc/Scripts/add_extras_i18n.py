import requests
import json
import sys
from string import Template

# Configuracin
CKAN_URL = 'https://estadisticas.arte-consultores.com/catalogo'
# Configuracin
API_KEY = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJCbU82X3BhMEpudzZnWWN6eE11bDVaT1Z4S0tScEJ0U09pM0ViY3FpM3NMWlRfX2Zmalo3bmtId3o2TlI2dHE5SGc4X193T2VXbDdzel95eCIsImlhdCI6MTczOTg3MTkzOX0.jeJGWFsIuZY0V2w9ustjpbNmvqyhfl6krIcMAUV1FOI'


# Funcin para obtener el paquete
def get_package(package_id):

    url = '%s/api/3/action/package_show?id=%s' % (CKAN_URL,package_id)
    headers = {
        'Authorization': f'{API_KEY}',
        'Content-Type': 'application/json'
    }

    data = {'id': package_id}
    response = requests.get(url, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()['result']
    else:
        print(f'Error al obtener el paquete: {response.status_code}')
        return None

# Funcin para actualizar el paquete con nuevos extras
def update_package(package_id, package):
    url = '%s/api/3/action/package_patch' % CKAN_URL
    headers = {
        'Authorization': f'{API_KEY}',
        'Content-Type': 'application/json'
    }
    print('VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV')
    print(json.dumps(package, indent=4))
    response = requests.post(url, headers=headers, json=package)
    if response.status_code == 200:
        print('Paquete actualizado correctamente')
    else:
        print(f'Error al actualizar el paquete: {response.status_code}')

# Verificar que se ha proporcionado un ID de paquete
if len(sys.argv) != 2:
    print('Uso: python script.py <package_id>')
    sys.exit(1)

# Obtener el ID del paquete desde la lnea de comandos
PACKAGE_ID = sys.argv[1]

# Obtener el paquete
packageg = get_package(PACKAGE_ID)
if packageg:

    p_title = packageg.get('title', '')
    p_desc = packageg.get('notes', 'Sin descripción')
    # TITLE
    title_t =  {
         "es": p_title
    }
    # DESCRIPTION
    desc_t =  {
         "es": p_desc if p_desc is not None else p_title
    }
    # Se crea un nuevo dict para solo enviar los campos a modificar
    # Se empezo haciendo con el objeto obtenido pero con todos los metadatos existentes en BBDD
    # Por lo que
    package = {}
    package['title_translated'] = title_t
    package['description_translated'] = desc_t

    pub = None
    theme = None
    identifier = None
    spatial = None
    language = None
    contact_email = None

    for item in packageg['extras']:
        print(item)
        if item['key'] == 'publisher_uri':
            pub = item['value']
        if item['key'] == 'theme':
            theme = item['value']
        if item['key'] == 'identifier':
            identifier = item['value']
        if item['key'] == 'spatial_uri':
            spatial = item['value']
        if item['key'] == 'language':
            language = item['value']
        if item['key'] == 'contact_email':
            contact_email = item['value']
    # PUBLISHER
    package['publisher'] = pub
    # IDENTIFIER
    if identifier is not None:
        package['identifier'] = identifier
    # THEME
    if theme is not None:
        package['theme'] =  theme.split(',')
    else:
        theme = packageg.get('theme', '')
        package['theme'] = theme[0].split(',')
    # SPATIAL
    package['spatial'] = spatial
    # EXTRAS
    package['extras'] = []
    # ID
    package['id'] = packageg.get('id', '')
    # CONTACT EMAIL
    package['contact_email'] = contact_email
    # LANGUAGE
    if language is not None:
        package['language'] = language.split(',')
    # RESOURCES
    resources = packageg.get('resources', '')
    resources_dict = []
    for resource in resources:
        rname = resource.get('name', '')
        rdesc = resource.get('description','')
        resource_dict = {
            "name_translated": { "es": resource.get('name', '')},
            "description_translated": { "es": rdesc if rdesc is not None else rname },
            "url": resource.get('url', ''),
            "format": resource.get('format',''),
            "mimetype": resource.get('format', ''),
            "created": resource.get('created',''),
            "mimetype": resource.get('mimetype', ''),
            "id": resource.get('id', ''),
            "package_id": resource.get('package_id', '')
        }
        resources_dict.append(resource_dict)

    package['resources'] = resources_dict

    print('KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK')
    print(packageg)
    # Actualizar el paquete con los nuevos extras
    update_package(PACKAGE_ID, package)
