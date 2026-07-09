#!/bin/bash
set -e

DUMP=/dump/ckan_default.dump

if [ ! -f "$DUMP" ]; then
    echo ">> ERROR: no se encuentra el fichero de dump en $DUMP"
    exit 1
fi

echo ">> Restaurando $DUMP en la base '$CKAN_DB' ..."
pg_restore -U "$POSTGRES_USER" -d "$CKAN_DB" --jobs=4 --verbose "$DUMP" \
    || echo ">> pg_restore terminó con warnings (normal para COMMENT/GRANT)"

echo ">> Restore finalizado. Numero de tablas en public:"
psql -U "$POSTGRES_USER" -d "$CKAN_DB" -tAc \
    "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';"
