FROM ckan/ckan-base:2.11.4

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

USER root

RUN mkdir /srv/app/.local && chown ckan /srv/app/.local && \
    mkdir /srv/app/.cache && chown ckan /srv/app/.cache

# Esto es para la versión 2.9
#RUN deluser ckan && \
#    addgroup -g 502 ckan && \
#    adduser -D -u 503 -G ckan ckan
#RUN chown -R ckan:ckan /srv/app /var/lib/ckan

# Install any extensions needed by your CKAN instance
# See Dockerfile.dev for more details and examples

USER ckan

COPY *.json .

## edatos plugins
#RUN git clone -b upgrade_ckan_2_11 https://apersan:glpat-zzB15xJzKcpjJxURoq9e@git.arte-consultores.com/istac/ckan-istac.git /tmp/ckan-istac && \
RUN git clone -b EDATOS-5261_ActualizacionCKANDockerizado https://jescgom:glpat-Pu_hF-P3xfKxB-FNcj1z@git.arte-consultores.com/istac/ckan-istac.git /tmp/ckan-istac && \
    #RUN git clone -b master https://apersan:glpat-zzB15xJzKcpjJxURoq9e@git.arte-consultores.com/istac/ckan-istac.git /tmp/ckan-istac && \
    mv /tmp/ckan-istac/ckanext-edatostheme src/ckanext-edatostheme && \
    chmod 777 src/ckanext-edatostheme/ckanext/edatostheme/templates/header.html && \
    chmod 777 src/ckanext-edatostheme/ckanext/edatostheme/templates/footer.html && \
    mv /tmp/ckan-istac/ckanext-cas src/ckanext-cas && \
    mv /tmp/ckan-istac/ckanext-edatosscheming src/ckanext-edatosscheming && \
    mv /tmp/ckan-istac/ckanext-gobcangroups src/ckanext-gobcangroups && \
    mv /tmp/ckan-istac/ckanext-edatosshowcase src/ckanext-edatosshowcase

# Esto es para la versión 2.9: Activamos el entorno python
#RUN . /usr/lib/ckan/venv/bin/activate

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
    mv /tmp/ckan-istac/etc/dcat\ custom\ profile/gobcan_profile.py src/ckanext-dcat/ckanext/dcat/profiles/. && \
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
RUN pip3 install -e src/ckanext-edatostheme && \
    pip3 install -e src/ckanext-cas && \
    pip3 install -r src/ckanext-edatosscheming/requirements.txt && \
    pip3 install -e src/ckanext-edatosscheming && \
    pip3 install -e src/ckanext-gobcangroups && \
    pip3 install -e src/ckanext-edatosshowcase


# Instalacion schming en el global de la imagen
#RUN /usr/local/bin/python -m pip install --no-cache-dir ckanext-scheming

# Revisar si no debemos incluir esto en requirements.txt del edatostheme
RUN pip3 install beautifulsoup4

USER root

# Para desarrollar con CKAN
RUN pip install flask_debugtoolbar
RUN apt install vim -y

RUN sed -i '/^\[logger_ckanext\]/,/^\[/ s/level = Info/level = DEBUG/' /srv/app/ckan.ini
RUN sed -i 's/^debug=false/debug=true/' /srv/app/ckan.ini


# Create necessary directories
RUN mkdir -p /docker-entrypoint.d /srv/app/docker/bin

# Copy custom initialization scripts
COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/

# Copy bin scripts for entrypoint
COPY --chown=ckan-sys:ckan-sys bin/ /srv/app/docker/bin/

# Hacer ejecutables todos los scripts sh y py
RUN chmod +x /docker-entrypoint.d/*.sh 2>/dev/null || true
RUN chmod +x /docker-entrypoint.d/*.py 2>/dev/null || true
RUN chmod +x /srv/app/docker/bin/*.py 2>/dev/null || true
RUN chmod +x /srv/app/docker/bin/*.sh 2>/dev/null || true

# scripts que se van a ejecutar
RUN echo "[Dockerfile] Scripts de entrypoint disponibles:" && ls -la /docker-entrypoint.d/


# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches

# Esto es para la versión 2.9
#RUN chown -R ckan:ckan /var/lib/ckan

USER ckan

RUN for d in $APP_DIR/patches/*; do \
    if [ -d $d ]; then \
    for f in `ls $d/*.patch | sort -g`; do \
    cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
    done ; \
    fi ; \
    done