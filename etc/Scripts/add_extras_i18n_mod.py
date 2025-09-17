import requests
import json
import sys
import argparse
import csv
from string import Template

# Configuracin
CKAN_URL = 'https://estadisticas.arte-consultores.com/catalogo'
# Configuracin
API_KEY = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJVZzlIQUh6MUppSzJ5QjhWdHNNU1BqdUVkQTJvVFVOODNHVzd5SldTZUVyUkZlMTFLbFdtZFVWdWRaWmIxSEpPRVVrd3FfSG1JMVdhNVNENyIsImlhdCI6MTc1ODAyOTgzMH0.To0HFTa2Qt1qGJ2qGC5B8QsFNFKzGPsHtVjEKKVCUVw'

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
        print(f'Error al obtener el paquete: {response.status_code} para {package_id}')
        return None

def update_package(package_id, package):
    url = '%s/api/3/action/package_patch' % CKAN_URL
    headers = {
        'Authorization': f'{API_KEY}',
        'Content-Type': 'application/json'
    }
    print('-------- ACTUALIZANDO PAQUETE --------')
    print(json.dumps(package, indent=4))
    response = requests.post(url, headers=headers, json=package)
    if response.status_code == 200:
        print('Paquete actualizado correctamente')
    else:
        print(f'Error al actualizar el paquete: {response.status_code} para {package_id}')

def process_package(package_id):
    packageg = get_package(package_id)
    if packageg:
        p_title = packageg.get('title', '')
        p_desc = packageg.get('notes', 'Sin descripción')
        title_t =  {"es": p_title}
        desc_t =  {"es": p_desc if p_desc is not None else p_title}
        package = {}
        # TITLE 
        package['title_translated'] = title_t
        # DESCRIPTION
        package['description_translated'] = desc_t
        pub = None
        theme = None
        identifier = None
        spatial = None
        language = None
        contact_email = None
        for item in packageg['extras']:
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
            if isinstance(theme, str):
                # Si es string, se separa por comas y limpiar espacios
                package['theme'] = [s.strip() for s in theme.split(",") if s.strip()]
            elif isinstance(theme, list):
                # Si ya es lista, devolver tal cual
                package['theme'] = theme
        # SPATIAL
        package['spatial'] = spatial
        # EXTRAS
        package['extras'] = []
        # IDENTIFIER
        package['id'] = packageg.get('id', '')
        # CONTACT EMAIL
        package['contact_email'] = contact_email
        # LANGUAGE
        if language is not None:
            package['language'] = language.split(',')
        
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
        update_package(package_id, package)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Procesar y actualizar paquetes.')
    parser.add_argument('package_id', nargs='?', help='ID del paquete a procesar')
    parser.add_argument('-l', '--list', help='Archivo CSV con lista de IDs')

    args = parser.parse_args()

    if args.list:
        # Procesar lista
        with open(args.list, newline='', encoding='utf-8') as f:
            reader = csv.reader(f)
            for row in reader:
                # Admite CSV con ID como primer valor de cada fila
                package_id = row
                print(f"\n=== Procesando paquete: {package_id} ===")
                process_package(package_id)
    elif args.package_id:
        # Procesar unico paquete
        process_package(args.package_id)
    else:
        print('Uso: python script.py <package_id>  o \n      python script.py -l <lista.csv>')
        sys.exit(1)
        
### Uso:
# - Solo 1 ID:  
#   `python script.py id_del_paquete`
# - Archivo CSV con lista (1 ID por línea):  
#   `python script.py -l lista.csv`
