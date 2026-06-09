import re
import requests
import json
import sys
import argparse
import csv
from string import Template

# Configuracin
CKAN_URL = 'https://mgcartera.gobiernodecanarias.net/catalogos/estadisticas'
# Configuracin
#P API_KEY = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJxY3pDZ2VUQkk4Y1ZTUTlmUGhoVTR1U2ZKYWdMRGV6S25wU3ZwSHBQOXhtOFhIRXJzMjhVZFpkU29ld0J3YVRfV09FSk55Wk1jY2RVTnZ0aiIsImlhdCI6MTc4MDQ4NzEzMX0.c4q1uVePPgfvQuNAi7lC6H_t3mG0V5BS5Wha-zXEGeo'

API_KEY = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJRS1A1dXFaOFpqMVRJbGNOeC13MkJYNWV4THpCWGJCWnJLNHRueUF0eS15OEk4X0c2aGZ1NmZEUkxrWHQ1Mm5EMi1ldm9CYzJmWUJwLUVoaCIsImlhdCI6MTc4MTAxMDM3Mn0.aS85kk58MwKp-aJ_pg950yZqIcVeYjylv1UipkQDDAI'
# ---------------------------------------------------------------------------
# Mapeo frecuencia: string español -> {type, value} para el preset date_frequency.
# Fuente: gobcan_profile.py _get_frequency_details.
# type debe ser uno de: days, weeks, months, years, hours, minutes, seconds.
# ---------------------------------------------------------------------------
FREQUENCY_MAP = {
    'anual':      {'type': 'years',  'value': 1},
    'semestral':  {'type': 'months', 'value': 6},
    'trimestral': {'type': 'months', 'value': 3},
    'bimensual':  {'type': 'months', 'value': 2},
    'mensual':    {'type': 'months', 'value': 1},
    'quincenal':  {'type': 'days',   'value': 15},
    'semanal':    {'type': 'days',   'value': 7},
    'diaria':     {'type': 'days',   'value': 1},
}

_FREQ_VALID_TYPES = frozenset(v['type'] for v in FREQUENCY_MAP.values())

def normalize_frequency(raw):
    """Devuelve {type, value} válido para date_frequency, o None si no es mapeable.

    Acepta:
    - dict ya con type/value (devuelto por date_frequency_output): se reenvía si es válido.
    - string español (Trimestral, Anual...): se mapea via FREQUENCY_MAP.
    - None, dict vacío {}, string vacío -> None (campo opcional, el validador acepta None).
    """
    if raw is None:
        return None
    if isinstance(raw, dict):
        t, v = raw.get('type'), raw.get('value')
        if t in _FREQ_VALID_TYPES and v not in (None, ''):
            try:
                int(v)
                return {'type': t, 'value': v}
            except (ValueError, TypeError):
                pass
        # {} o dict con claves inválidas: enviar type/value vacíos para que el
        # validador los acepte (ambos falsy + campo no required -> data[key]=None).
        return {'type': '', 'value': ''}
    if isinstance(raw, str):
        freq_key = raw.strip().lower()
        return FREQUENCY_MAP.get(freq_key)  # None si no está en la tabla
    return None

# ---------------------------------------------------------------------------
# Validación de nombres de tag según reglas de CKAN:
# 2-100 chars; letras, dígitos, espacios, guion, guion_bajo, punto.
# ---------------------------------------------------------------------------
_TAG_NAME_RE = re.compile(r'^[\w \-\.]{2,100}$', re.UNICODE)

def valid_tag_names(tags):
    """Extrae nombres de tag válidos de la lista core `tags` de package_show."""
    names = []
    for t in tags or []:
        name = t.get('name') if isinstance(t, dict) else t
        if isinstance(name, str) and _TAG_NAME_RE.match(name.strip()):
            names.append(name.strip())
    return names

def get_package(package_id):
    url = '%s/api/3/action/package_show?id=%s' % (CKAN_URL,package_id)
    headers = {
        'Authorization': f'{API_KEY}',
        'Content-Type': 'application/json'
    }
    data = {'id': package_id}
    response = requests.get(url, headers=headers, json=data, verify=False)
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
    response = requests.post(url, headers=headers, json=package, verify=False)
    if response.status_code == 200:
        print('Paquete actualizado correctamente')
    else:
        print(f'Error al actualizar el paquete: {response.status_code} para {package_id}')
        try:
            error_info = response.json()
            error_message = error_info.get('error', {}).get('message', 'Mensaje no disponible')
            error_cause = error_info.get('error', {}).get('cause', 'Causa no disponible')
            print(f'Número del error: {response.status_code}')
            print(f'Mensaje: {error_message}')
            print(f'Causa: {error_cause}')
            print('Error Response', error_info)
        except Exception as e:
            print('No se pudo parsear el cuerpo de la respuesta como JSON.', error_info)
            print(f'Error interno: {str(e)}')
            print(f'Respuesta completa: {response.text}')

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
        freq_raw = None
        if 'extras' in packageg and packageg['extras'] is not None:
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
                if item['key'] == 'frequency':
                    freq_raw = item['value']
        # frequency puede venir como extra string ("Trimestral") o como campo de primer
        # nivel (dict {type,value} si ya pasó por date_frequency_output en el esquema nuevo).
        if freq_raw is None:
            freq_raw = packageg.get('frequency')
        # PUBLISHER
        if pub is not None:
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
        if spatial is not None:
            package['spatial'] = spatial
        # FREQUENCY: mapear string español -> {type, value}.
        # Siempre se incluye: normalize_frequency devuelve {type,value} real si
        # hay mapeo, o {type:'',value:''} para limpiar un {} roto almacenado.
        # Nunca se envía None: el validador rechaza null con "Expecting JSON object".
        package['frequency'] = normalize_frequency(freq_raw)
        # EXTRAS
        package['extras'] = []
        # IDENTIFIER
        package['id'] = packageg.get('id', '')
        # CONTACT EMAIL
        if contact_email is not None:
            package['contact_email'] = contact_email
        elif 'contact_email' in packageg and packageg['contact_email'] is not None:
            package['contact_email'] = packageg['contact_email']
        # LANGUAGE
        if language is not None:
            package['language'] = language.split(',')
        # TAGS -> multilingual_tags (asumimos español).
        # copy_fluent_keywords_to_tags sincroniza la lista core `tags` automáticamente,
        # así que NO se incluye `package['tags']` para evitar conflictos.
        tag_names = valid_tag_names(packageg.get('tags'))
        if tag_names:
            package['multilingual_tags'] = {'es': tag_names}

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
        print()
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
                package_id = row[0].strip()
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
#  nohup python add_extra_i18n_mod.py -l datasets_migrar.csv &
#   

