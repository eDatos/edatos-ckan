#!/bin/bash

# debug false a true
sed -i 's/^debug=false/debug=true/' /srv/app/ckan.ini

# Ckan logger level a DEBUG
sed -i '/^\[logger_ckanext\]/,/^\[/ s/level = Info/level = DEBUG/' /srv/app/ckan.ini

# Se comenta todo el contenido del script 02_setup_xloader.sh
sed -i '/./ s/^/#/' /docker-entrypoint.d/02_setup_xloader.sh