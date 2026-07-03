#!/usr/bin/env sh
# Construye la version compuesta PEP 440 para las extensiones ckan-istac.
# Formato: <tag_gitlab>+ckan.<ckan_core_major.minor>
#
# Uso:
#   sh set_version.sh [ruta_dockerfile]
#   CI_COMMIT_TAG=10.0.0 sh set_version.sh          # -> 10.0.0+ckan.2.11
#   sh set_version.sh                                 # -> 0.0.0.dev0+ckan.2.11 (build dev, sin tag)
#
# Requiere: sh, grep, cut, printf (disponibles en docker:24.0.5 / alpine).
set -eu

DOCKERFILE="${1:-dockerfiles/ckan/Dockerfile}"

# Segmento local: 'ckan.' + MAJOR.MINOR de CKAN core, leido del FROM ckan-base del Dockerfile.
CORE="$(grep -oE 'ckan-base:[0-9]+\.[0-9]+' "$DOCKERFILE" | head -n1 | cut -d: -f2)"
CORE="${CORE:-2.11}"
LOCAL="ckan.${CORE}"

# Segmento publico: tag de GitLab.
#   - Se elimina 'v' inicial si lo hubiera (p.ej. v10.0.0 -> 10.0.0).
#   - PEP 440 exige que el publico sea numerico (con separadores opcionales
#     de pre/post/dev); se asume tag tipo semver (X.Y.Z, X.Y.Z-rc1, etc.).
#   - Sin tag (build manual, IMAGE_TAG=latest): version de desarrollo valida
#     "0.0.0.dev0", que ademas ordena por debajo de cualquier release real.
TAG="${CI_COMMIT_TAG:-}"
if [ -n "$TAG" ]; then
    PUBLIC="${TAG#v}"
else
    PUBLIC="0.0.0.dev0"
fi

printf '%s+%s\n' "$PUBLIC" "$LOCAL"
