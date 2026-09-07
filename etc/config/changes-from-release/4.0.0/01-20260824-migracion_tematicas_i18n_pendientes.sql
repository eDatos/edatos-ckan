-- NOTA:
-- Este script vuelve a aplicar la correccion del campo "theme" de package_extra
-- para los datasets que, a fecha 2026-08-24, siguen devolviendo el error E4005
-- ("El campo Temáticas (dcat:theme) tiene un valor no válido") en
-- pre-datos.canarias.es. Son 34 de los 105 datasets ya corregidos en
-- 02-20260622-migracion_tematicas_i18n.sql; los mismos id/value se reutilizan
-- de ese script porque corresponden al mismo entorno.

-- Antes de ejecutar, comprobar que las filas siguen sin ser un array JSON
-- valido (mismo patron que 03-20260622-verificacion_tematicas_i18n.sql):
--
-- SELECT id, value FROM package_extra
-- WHERE id IN ('a523aeed-719a-4945-a1db-c7c98a1c0162','857e4d72-d328-4842-8707-a7a6e4a30b34',
--              '83e7baf7-161d-4319-976b-278f608c6dd4','84fee9d3-8ab6-45e0-a9bf-43d6bede2406',
--              '4de08ad9-fab8-4ef6-8e8b-c4809ca75314','11daa088-f78e-4e6a-85a2-392c286573c6',
--              '7c17c431-c45c-431a-afe9-7530b0212e5e','342f75a2-c2ed-4ff7-85c8-0f8f768e3161',
--              '60227b3d-57ef-4993-b86b-26e9c830e055','5f36d0ec-2784-4fbe-a7de-50f749c43817',
--              '9fb3b91d-d560-4292-b88f-38f8c1faed26','36b0e6f0-eb39-44aa-b27d-b5565215dbaa',
--              '1a35e147-4417-4b59-8405-51b980b62bf0','a22469a6-b563-4d0c-9863-3b66ce464cc0',
--              '18c18c5c-ff73-4334-9396-4bcbb3554a43','280ddac9-f3e0-470a-928d-ba0a3a16d80b',
--              '8fc74427-7b78-4a19-8217-51b654517ba5','373fe573-d407-48ff-99b4-fa638d8907a8',
--              '26242f73-2c9c-4f14-b616-fa1464d62eee','3362c8f8-cca7-428e-98e9-0df9ab508d00',
--              'af403a16-a1e1-410e-9d28-605595076f0d','d2bd5ee2-9281-4f7b-835b-bab25e7730ab',
--              'f84c6091-f778-4699-8aea-66f1fa22b391','f7f8aeab-2d30-436d-8ecc-d5ba79d647cb',
--              '0df8aa5a-cdb1-418f-994e-5c8858f6a734','2d3ec7db-3c1c-49d2-ac3c-e424c39d1979',
--              '5dbce508-595f-466c-9502-4cdb80620c0f','c690d500-ce07-448c-a0c7-6e56633ea420',
--              'b1c9ac78-275d-46de-b121-bb3b28457898','67fa7a62-d603-4533-981e-7e79901a15ea',
--              'e436759d-4ffd-4d6d-8134-30150c89cb6e','8528a1d9-a79e-4308-8f19-f5a7e0a97041',
--              '52edc0a1-27bf-40b8-afb2-4f1d8ab5486a','32c0e7e5-f2b2-4582-9ca4-66359acb8e6b')
-- AND value NOT LIKE '[%';

-- WHERE por id (PK de package_extra) => idempotente y seguro.
-- IMPORTANTE: esto NO reindexa Solr. Tras el COMMIT, reindexar los paquetes
--            (ckan search-index rebuild <package_id>) o re-disparar el harvest.

BEGIN;

-- pkg 52b3ed88-7649-4971-ba71-c850c4284aa1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/transporte","http://datos.gob.es/kos/sector-publico/sector/turismo"]' WHERE id = 'a523aeed-719a-4945-a1db-c7c98a1c0162' AND key = 'theme';
-- pkg 44dc4231-b23c-464d-a0b3-709c55ff4571
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '857e4d72-d328-4842-8707-a7a6e4a30b34' AND key = 'theme';
-- pkg e1b1832e-72c3-4a85-aa82-0167493022b7
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '83e7baf7-161d-4319-976b-278f608c6dd4' AND key = 'theme';
-- pkg d7060d12-0fc4-4c6a-b687-865c1e51db7b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '84fee9d3-8ab6-45e0-a9bf-43d6bede2406' AND key = 'theme';
-- pkg 1f8a16e1-11dc-4bb1-8d6b-3ce1c3328b48
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '4de08ad9-fab8-4ef6-8e8b-c4809ca75314' AND key = 'theme';
-- pkg 565b40cc-0392-49be-8914-10381d5f1ed1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '11daa088-f78e-4e6a-85a2-392c286573c6' AND key = 'theme';
-- pkg e5d29c5e-8db9-4d4a-bad6-c91d160c2d6b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '7c17c431-c45c-431a-afe9-7530b0212e5e' AND key = 'theme';
-- pkg 91d18bee-cbad-465b-8ddb-bf532022c166
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '342f75a2-c2ed-4ff7-85c8-0f8f768e3161' AND key = 'theme';
-- pkg 02d59b92-4836-4f22-a8a6-2c0954d74bf4
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '60227b3d-57ef-4993-b86b-26e9c830e055' AND key = 'theme';
-- pkg 5eb59323-60ba-46a1-a13f-2cdcb38bd85a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '5f36d0ec-2784-4fbe-a7de-50f749c43817' AND key = 'theme';
-- pkg 946b00f4-f91f-4d8b-b917-88832a5c578a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '9fb3b91d-d560-4292-b88f-38f8c1faed26' AND key = 'theme';
-- pkg e47b0a8f-211e-45ab-859e-ce53a85fa8aa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '36b0e6f0-eb39-44aa-b27d-b5565215dbaa' AND key = 'theme';
-- pkg bc31e4d9-466f-4f28-a343-a4175b9d4e97
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '1a35e147-4417-4b59-8405-51b980b62bf0' AND key = 'theme';
-- pkg da5e3add-84d3-40f3-9eb1-64b27b1db72c
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'a22469a6-b563-4d0c-9863-3b66ce464cc0' AND key = 'theme';
-- pkg 79eb47f7-bb4d-408c-a12b-c565130b864a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '18c18c5c-ff73-4334-9396-4bcbb3554a43' AND key = 'theme';
-- pkg 48127e71-93cd-4bae-ac17-4319720a6e56
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '280ddac9-f3e0-470a-928d-ba0a3a16d80b' AND key = 'theme';
-- pkg 7f10d1ea-3354-409a-8038-5fa4475d931d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '8fc74427-7b78-4a19-8217-51b654517ba5' AND key = 'theme';
-- pkg cebf9052-3d87-459b-9262-7b831b6148aa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '373fe573-d407-48ff-99b4-fa638d8907a8' AND key = 'theme';
-- pkg 0e5d2a9f-b8e1-4ae7-aa53-6b829b360472
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '26242f73-2c9c-4f14-b616-fa1464d62eee' AND key = 'theme';
-- pkg 3c59e083-d606-4ef8-a0b3-8d3bc3cd39bc
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '3362c8f8-cca7-428e-98e9-0df9ab508d00' AND key = 'theme';
-- pkg da3a973d-c608-4838-83c8-a7fded800703
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'af403a16-a1e1-410e-9d28-605595076f0d' AND key = 'theme';
-- pkg 1a7c390d-187b-4fa0-a9e7-fe78d0c1d3f4
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'd2bd5ee2-9281-4f7b-835b-bab25e7730ab' AND key = 'theme';
-- pkg dc327e7b-ddac-4fc4-afb0-445a6e191525
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'f84c6091-f778-4699-8aea-66f1fa22b391' AND key = 'theme';
-- pkg 1000bcd5-879e-4d1a-88c1-d9380df568eb
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'f7f8aeab-2d30-436d-8ecc-d5ba79d647cb' AND key = 'theme';
-- pkg c4d6d28a-ccc8-4e3b-b6f9-0f652bca7aa7
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '0df8aa5a-cdb1-418f-994e-5c8858f6a734' AND key = 'theme';
-- pkg 7a13e952-e3ba-431d-b187-52c5ec340ae2
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '2d3ec7db-3c1c-49d2-ac3c-e424c39d1979' AND key = 'theme';
-- pkg 762e5bbc-d3d9-40ff-a13a-e783320790a2
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '5dbce508-595f-466c-9502-4cdb80620c0f' AND key = 'theme';
-- pkg a96043aa-db32-439d-9ba1-b192faae2e62
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'c690d500-ce07-448c-a0c7-6e56633ea420' AND key = 'theme';
-- pkg f31fdd2a-5d68-4f6e-a121-bfdaf86ca52c
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'b1c9ac78-275d-46de-b121-bb3b28457898' AND key = 'theme';
-- pkg 2ab78abd-942a-4acf-8be5-1b1018ea7a9b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '67fa7a62-d603-4533-981e-7e79901a15ea' AND key = 'theme';
-- pkg 6220e57e-48ee-4d40-9c31-9b3934c40a18
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'e436759d-4ffd-4d6d-8134-30150c89cb6e' AND key = 'theme';
-- pkg 8591dcfa-29ce-4f68-b58c-1c725a87c23b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '8528a1d9-a79e-4308-8f19-f5a7e0a97041' AND key = 'theme';
-- pkg 1a20a85e-dbf8-41ed-a773-a8cfe850145e
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '52edc0a1-27bf-40b8-afb2-4f1d8ab5486a' AND key = 'theme';
-- pkg 2e5b47db-7e2b-4333-9dc0-4ece1bef50c0
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '32c0e7e5-f2b2-4582-9ca4-66359acb8e6b' AND key = 'theme';

COMMIT;
