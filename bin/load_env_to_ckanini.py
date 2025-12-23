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

def load_env_file(env_file):
    """
    Carga variables desde archivo .env
    Retorna diccionario {key: value}
    """
    env_vars = {}
    if not os.path.exists(env_file):
        print(f"Archivo .env no encontrado: {env_file}")
        return env_vars
    
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
    
    return env_vars

def convert_env_to_ckan_ini(env_vars):
    """
    Convierte variables de entorno CKAN_* a formato ckan.ini
    
    Ejemplos:
    - CKAN_SITE_URL -> ckan.site_url
    - CKAN_LOCALE_DEFAULT -> ckan.locale_default
    - CKAN___BEAKER__SESSION__SECRET -> ckan.beaker.session.secret
    - CKAN__PLUGINS -> ckan.plugins
    """
    ckan_config = {}
    
    for env_key, env_value in env_vars.items():
        if not env_key.startswith('CKAN'):
            continue
        
        # Remover prefijo CKAN_ o CKAN__
        if env_key.startswith('CKAN___'):
            # Triple guión: CKAN___BEAKER__SESSION__SECRET
            config_key = env_key[7:].lower()  # Remover "CKAN___"
            config_key = config_key.replace('__', '.')
        elif env_key.startswith('CKAN__'):
            # Doble guión: CKAN__PLUGINS
            config_key = env_key[6:].lower()  # Remover "CKAN__"
            config_key = config_key.replace('__', '.')
        elif env_key.startswith('CKAN_'):
            # Simple guión: CKAN_SITE_URL
            config_key = env_key[5:].lower()  # Remover "CKAN_"
            config_key = config_key.replace('_', '.')
        else:
            continue
        
        ckan_config[f'ckan.{config_key}'] = env_value
    
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
    ckan_config_dir = os.environ.get('CKAN_CONFIG', '/etc/ckan/default')
    ckan_ini_path = os.path.join(ckan_config_dir, 'ckan.ini')
    
    # Si se pasa por argumento, usarlo
    if len(sys.argv) > 1:
        ckan_ini_path = sys.argv[1]
    
    # Buscar .env en directorio actual o en /srv/app
    env_file = '.env'
    if not os.path.exists(env_file):
        env_file = '/srv/app/.env'
    if not os.path.exists(env_file):
        env_file = '/srv/app/docker/.env'
    
    print(f"📖 Leyendo variables de entorno desde: {env_file}")
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
        print("No se encontraron variables CKAN en .env")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)