#!/usr/bin/env sh
# Construye la version compuesta PEP 440 para las extensiones ckan-istac.
# Formato: <tag_gitlab>+ckan.<ckan_core_major.minor>
#
# Uso:
#   sh set_version.sh [ruta_dockerfile]
#   CI_COMMIT_TAG=10.0.0 sh set_version.sh          # -> 10.0.0+ckan.2.11
#   sh set_version.sh                                 # -> 03-07-2026-1530-snapshot (sin tag)
#
# Requiere: sh, grep, cut, date, printf (disponibles en docker:24.0.5 / alpine).
set -eu

DOCKERFILE="${1:-dockerfiles/ckan/Dockerfile}"

# Sin tag de GitLab no hay version que propagar: se usa el mismo formato de
# snapshot con fecha que el fallback local de cada setup.py, para que un build
# manual/dev (IMAGE_TAG=latest) sea identificable a simple vista como no-release.
TAG="${CI_COMMIT_TAG:-}"
if [ -z "$TAG" ]; then
    printf '%s-snapshot\n' "$(date +'%d-%m-%Y-%H%M')"
    exit 0
fi

# Segmento publico: tag de GitLab, sin la 'v' inicial si la tuviera
# (p.ej. v10.0.0 -> 10.0.0). PEP 440 exige que el publico sea numerico (con
# separadores opcionales de pre/post/dev); se asume tag tipo semver
# (X.Y.Z, X.Y.Z-rc1, etc.).
PUBLIC="${TAG#v}"

# Segmento local: 'ckan.' + MAJOR.MINOR de CKAN core, leido del FROM ckan-base del Dockerfile.
CORE="$(grep -oE 'ckan-base:[0-9]+\.[0-9]+' "$DOCKERFILE" | head -n1 | cut -d: -f2)"
CORE="${CORE:-2.11}"
LOCAL="ckan.${CORE}"

printf '%s+%s\n' "$PUBLIC" "$LOCAL"
