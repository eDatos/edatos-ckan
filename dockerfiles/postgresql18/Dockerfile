FROM postgres:18-alpine

# Scripts de inicializacion (crean roles/bases y restauran el dump en el primer arranque)
COPY --chown=postgres:postgres docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
