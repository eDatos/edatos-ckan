-- NOTA:
-- Fix puntual para un registro que quedo fuera del script 04 porque no
-- aparecia en la lista de errores E4005 usada para generarlo, pero al
-- verificar contra los 105 ids de 03-20260622-verificacion_tematicas_i18n.sql
-- se detecto que sigue con el valor concatenado por comas.

-- Antes de ejecutar, comprobar que la fila sigue sin ser un array JSON valido:
--
-- SELECT id, value FROM package_extra
-- WHERE id = '39dabf7a-ef6f-47ef-abde-fd494c0b0521'
-- AND value NOT LIKE '[%';

-- WHERE por id (PK de package_extra) => idempotente y seguro.
-- IMPORTANTE: esto NO reindexa Solr. Tras el COMMIT, reindexar el paquete
--            (ckan search-index rebuild <package_id>) o re-disparar el harvest.

BEGIN;

-- pkg 194d1360-c7fa-4e15-a87b-1da93ddd21b2
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '39dabf7a-ef6f-47ef-abde-fd494c0b0521' AND key = 'theme';

COMMIT;
