#!/usr/bin/env sh
# Construye la version compuesta PEP 440 para las extensiones ckan-istac.
# Formato: <ckan_core_major.minor>+edatos.<tag_sanitizado>
#
# Uso:
#   sh set_version.sh [ruta_dockerfile]
#   CI_COMMIT_TAG=10.0.0 sh set_version.sh          # -> 2.11+edatos.10.0.0
#   sh set_version.sh                                 # -> 2.11+edatos.latest (build dev)
#
# Requiere: sh, grep, sed, cut, printf (disponibles en docker:24.0.5 / alpine).
set -eu

DOCKERFILE="${1:-dockerfiles/ckan/Dockerfile}"

# Segmento publico: MAJOR.MINOR de CKAN core, leido del FROM ckan-base del Dockerfile.
CORE="$(grep -oE 'ckan-base:[0-9]+\.[0-9]+' "$DOCKERFILE" | head -n1 | cut -d: -f2)"
CORE="${CORE:-2.11}"

# Segmento local: 'edatos.' + tag saneado.
#   - Se elimina 'v' inicial si lo hubiera (p.ej. v10.0.0 -> 10.0.0).
#   - Cualquier secuencia de caracteres no alfanumericos se reemplaza por '.'.
#   - PEP 440 normaliza '-' y '_' a '.' en el segmento local; usamos '.' directamente.
TAG="${CI_COMMIT_TAG:-}"
if [ -n "$TAG" ]; then
    TAG="${TAG#v}"
    LOCAL="edatos.$(printf '%s' "$TAG" | sed 's/[^A-Za-z0-9]\{1,\}/./g')"
else
    LOCAL="edatos.latest"   # build manual sin tag (IMAGE_TAG=latest)
fi

printf '%s+%s\n' "$CORE" "$LOCAL"
