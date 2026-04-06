FROM ckan/ckan-base:2.11.4

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

USER root

RUN mkdir /srv/app/.local && chown ckan /srv/app/.local && \
    mkdir /srv/app/.cache && chown ckan /srv/app/.cache

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

USER ckan

COPY dockerfiles/ckan/*.json .

COPY --chown=ckan:ckan ckanext-cas/ src/ckanext-cas/
COPY --chown=ckan:ckan ckanext-edatosscheming/ src/ckanext-edatosscheming/
COPY --chown=ckan:ckan ckanext-gobcangroups/ src/ckanext-gobcangroups/
COPY --chown=ckan:ckan ckanext-edatosshowcase/ src/ckanext-edatosshowcase/
COPY --chown=ckan:ckan ckanext-edatostheme/ src/ckanext-edatostheme/
COPY --chown=ckan:ckan ckanext-istactranslation src/ckanext-istactranslation/
COPY --chown=ckan:ckan ["etc/dcat custom profile/gobcan_profile.py", "/tmp/gobcan_profile.py"]



## edatos plugins actualizamos permisos 
RUN chmod 777 src/ckanext-edatostheme/ckanext/edatostheme/templates/header.html && \
    chmod 777 src/ckanext-edatostheme/ckanext/edatostheme/templates/footer.html

### XLoader ###
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-xloader.git@2.2.0#egg=ckanext-xloader' && \
    pip3 install -r ${APP_DIR}/src/ckanext-xloader/requirements.txt && \
    pip3 install -U requests[security]

### GeoView ###
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-geoview.git@v0.2.2#egg=ckanext-geoview'
#RUN git clone https://github.com/ckan/ckanext-geoview.git /srv/app/src/ckanext-geoview && \
#    cd /srv/app/src/ckanext-geoview && \
#    git checkout tags/0.2.2 && \
#    pip install -e .

### showcase ###
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-showcase.git@v1.8.4#egg=ckanext-showcase' && \
    pip3 install -r ${APP_DIR}/src/ckanext-showcase/requirements.txt

### DCat ###
#RUN  pip3 install -e git+https://github.com/ckan/ckanext-dcat.git@master#egg=ckanext-dcat && \
RUN  git clone --branch v2.4.2 --single-branch https://github.com/ckan/ckanext-dcat.git /srv/app/src/ckanext-dcat && \
    mv /tmp/gobcan_profile.py src/ckanext-dcat/ckanext/dcat/profiles/. && \
    echo 'gobcan_dcat_ap = "ckanext.dcat.profiles.gobcan_profile:GobCanProfile"\n' >> src/ckanext-dcat/pyproject.toml && \
    pip3 install -e /srv/app/src/ckanext-dcat && \
    pip3 install -r ${APP_DIR}/src/ckanext-dcat/requirements.txt

### Harvester ###
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-harvest.git@v1.6.1#egg=ckanext-harvest' && \
    pip3 install -r ${APP_DIR}/src/ckanext-harvest/pip-requirements.txt


### Scheming and fluent
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming'
RUN pip3 install -e 'git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent'

### Custom plugins

RUN pip3 install -r src/ckanext-edatostheme/requirements.txt && \
    pip3 install -e src/ckanext-edatostheme && \
    pip3 install -e src/ckanext-cas && \
    pip3 install -r src/ckanext-edatosscheming/requirements.txt && \
    pip3 install -e src/ckanext-edatosscheming && \
    pip3 install -e src/ckanext-gobcangroups && \
    pip3 install -e src/ckanext-edatosshowcase

# Generar schemas por defecto desde los templates (con locale 'es') para que
# nunca estén vacíos durante el arranque. 
#El entrypoint 01_fill_schemas_templates.sh
# los regenerará en runtime con el valor real de CKAN__LOCALE_DEFAULT de .env
RUN for f in src/ckanext-edatosscheming/ckanext/edatosscheming/schemas_templates/*.json; do \
    sed 's/FILL_REQUIRED_LANGUAGE/es/g' "$f" \
    > "src/ckanext-edatosscheming/ckanext/edatosscheming/schemas/$(basename $f)"; \
    done

USER root

# Create necessary directories
RUN mkdir -p /docker-entrypoint.d /srv/app/docker/bin

# Copy custom initialization scripts
COPY --chown=ckan-sys:ckan-sys dockerfiles/ckan/docker-entrypoint.d/* /docker-entrypoint.d/

# Normalizar finales de línea (CRLF -> LF) para scripts copiados desde Windows
RUN find /docker-entrypoint.d -type f \( -name "*.sh" -o -name "*.py" \) -exec sed -i 's/\r$//' {} + && \
    find /srv/app/docker/bin -type f \( -name "*.sh" -o -name "*.py" \) -exec sed -i 's/\r$//' {} +

# Hacer ejecutables todos los scripts sh y py
RUN chmod +x /docker-entrypoint.d/*.sh 2>/dev/null || true
RUN chmod +x /docker-entrypoint.d/*.py 2>/dev/null || true
RUN chmod +x /srv/app/docker/bin/*.py 2>/dev/null || true
RUN chmod +x /srv/app/docker/bin/*.sh 2>/dev/null || true

# scripts que se van a ejecutar
RUN echo "[Dockerfile] Scripts de entrypoint disponibles:" && ls -la /docker-entrypoint.d/

# Override wsgi.py to add ProxyFix (required for CSRF behind reverse proxy)
COPY --chown=ckan-sys:ckan-sys dockerfiles/ckan/setup/wsgi.py /srv/app/wsgi.py
RUN sed -i 's/\r$//' /srv/app/wsgi.py

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY --chown=ckan-sys:ckan-sys dockerfiles/ckan/patches ${APP_DIR}/patches

USER ckan

RUN for d in $APP_DIR/patches/*; do \
    if [ -d $d ]; then \
    for f in `ls $d/*.patch | sort -g`; do \
    cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
    done ; \
    fi ; \
    done
