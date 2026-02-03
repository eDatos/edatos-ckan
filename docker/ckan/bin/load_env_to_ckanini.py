#!/usr/bin/env python3
# docker/bin/load_env_to_ckan_ini.py
"""
Script para leer variables de .env y mapearlas a ckan.ini
Soporta variables con prefijo CKAN_ y CKAN__ (para config anidada)
"""

import os
import sys
import re
from pathlib import Path
from configparser import ConfigParser

def load_env_file(env_file=None):
    """
    Carga variables desde archivo .env o desde variables de entorno del sistema
    Si el archivo .env existe, lo lee. Si no, usa os.environ
    Retorna diccionario {key: value}
    """
    env_vars = {}
    
    # Si se proporciona ruta del archivo .env, intentar leerlo
    if env_file and os.path.exists(env_file):
        print(f"Leyendo variables de entorno desde: {env_file}")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                # Ignorar comentarios y líneas vacías
                if not line or line.startswith('#'):
                    continue
                
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    # Remover comillas si existen
                    if value.startswith('"') and value.endswith('"'):
                        value = value[1:-1]
                    elif value.startswith("'") and value.endswith("'"):
                        value = value[1:-1]
                    env_vars[key] = value
    else:
        # Si no existe archivo .env, usar variables de entorno del sistema
        print("Leyendo variables de entorno del sistema (no hay archivo .env)")
        env_vars = dict(os.environ)
    
    return env_vars

def convert_env_to_ckan_ini(env_vars):
    """
    Convierte variables de entorno CKAN_* y CKANEXT_* a formato ckan.ini
    
    Ejemplos:
    - CKAN_SITE_URL -> ckan.site_url
    - CKAN_LOCALE_DEFAULT -> ckan.locale_default
    - CKAN___BEAKER__SESSION__SECRET -> ckan.beaker.session.secret
    - CKAN__PLUGINS -> ckan.plugins
    - CKANEXT_SCHEMING_PRESET_SCHEMAS -> ckanext.scheming.preset_schemas
    """
    ckan_config = {}
    
    for env_key, env_value in env_vars.items():
        config_key = None
        
        # Procesar variables CKAN
        if env_key.startswith('CKAN___'):
            # Triple guión: CKAN___BEAKER__SESSION__SECRET
            config_key = env_key[7:].lower()  # Remover "CKAN___"
            config_key = config_key.replace('__', '.')
            config_key = f'ckan.{config_key}'
        elif env_key.startswith('CKAN__'):
            # Doble guión: CKAN__PLUGINS
            config_key = env_key[6:].lower()  # Remover "CKAN__"
            config_key = config_key.replace('__', '.')
            config_key = f'ckan.{config_key}'
        elif env_key.startswith('CKAN_'):
            # Simple guión: CKAN_SITE_URL
            config_key = env_key[5:].lower()  # Remover "CKAN_"
            config_key = config_key.replace('_', '.')
            config_key = f'ckan.{config_key}'
        
        # Procesar variables CKANEXT
        elif env_key.startswith('CKANEXT___'):
            # Triple guión: CKANEXT___SCHEMING__PRESET_SCHEMAS
            config_key = env_key[10:].lower()  # Remover "CKANEXT___"
            config_key = config_key.replace('__', '.')
            config_key = f'ckanext.{config_key}'
        elif env_key.startswith('CKANEXT__'):
            # Doble guión: CKANEXT__SCHEMING__PLUGINS
            config_key = env_key[9:].lower()  # Remover "CKANEXT__"
            config_key = config_key.replace('__', '.')
            config_key = f'ckanext.{config_key}'
        elif env_key.startswith('CKANEXT_'):
            # Simple guión: CKANEXT_SCHEMING_PRESET_SCHEMAS
            config_key = env_key[8:].lower()  # Remover "CKANEXT_"
            config_key = config_key.replace('_', '.')
            config_key = f'ckanext.{config_key}'
        
        if config_key:
            ckan_config[config_key] = env_value
    
    return ckan_config

def update_ckan_ini(ckan_ini_path, ckan_config):
    """
    Actualiza el archivo ckan.ini con los valores del .env
    """
    if not os.path.exists(ckan_ini_path):
        print(f"ERROR: Archivo ckan.ini no encontrado: {ckan_ini_path}")
        return False
    
    config = ConfigParser()
    config.read(ckan_ini_path)
    
    # Asegurar que existe la sección [app:main]
    if 'app:main' not in config:
        config['app:main'] = {}
    
    # Actualizar con variables del .env
    updated_count = 0
    for config_key, value in ckan_config.items():
        old_value = config.get('app:main', config_key, fallback=None)
        config.set('app:main', config_key, value)
        
        if old_value != value:
            print(f"  ✓ {config_key} = {value}")
            updated_count += 1
        else:
            print(f"  - {config_key} = {value} (sin cambios)")
    
    # Escribir cambios a ckan.ini
    try:
        with open(ckan_ini_path, 'w') as f:
            config.write(f)
        print(f"\nActualizado: {ckan_ini_path} ({updated_count} cambios)")
        return True
    except Exception as e:
        print(f"ERROR al escribir ckan.ini: {e}")
        return False

def main():
    # Rutas por defecto
    ckan_config_dir = os.environ.get('CKAN_CONFIG', '/srv/app')
    ckan_ini_path = os.path.join(ckan_config_dir, 'ckan.ini')
    
    # Si se pasa por argumento, usarlo
    if len(sys.argv) > 1:
        ckan_ini_path = sys.argv[1]
    
    # Buscar .env en directorio actual o en /srv/app (opcional)
    env_file = None
    for path in ['.env', '/srv/app/.env', '/srv/app/docker/.env']:
        if os.path.exists(path):
            env_file = path
            break
    
    # Cargar variables (de archivo .env si existe, o del sistema)
    env_vars = load_env_file(env_file)
    
    if not env_vars:
        print("No se encontraron variables de entorno")
        return False
    
    print(f"✓ Variables de entorno cargadas: {len(env_vars)}")
    
    # Convertir y filtrar solo variables CKAN
    ckan_config = convert_env_to_ckan_ini(env_vars)
    
    if ckan_config:
        print(f"\n Mapeando {len(ckan_config)} variables CKAN a ckan.ini:")
        print(f"   Archivo destino: {ckan_ini_path}\n")
        return update_ckan_ini(ckan_ini_path, ckan_config)
    else:
        print("No se encontraron variables CKAN en el entorno")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)