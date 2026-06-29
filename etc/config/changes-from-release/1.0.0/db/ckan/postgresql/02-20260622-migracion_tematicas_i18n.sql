-- NOTA:
-- Este script actualiza el campo "theme" de los datasets con un array JSON válido, reemplazando el valor anterior que estaba concatenado por comas. Se utiliza la clave primaria (id) de la tabla package_extra para asegurar que solo se actualicen los registros correctos.

-- Se debe ejecutar para los conjuntos de datos que posean un valor en el campo "theme" que esté concatenado por comas, y que necesiten ser convertidos a un formato de array JSON válido para cumplir con los requisitos de internacionalización.

-- Los IDs de los datasets se obtienen de la tabla package_extra, y se actualizan solo aquellos que tienen el campo "theme" con un valor concatenado por comas en el momento de la implementación de la internacionalización.


-- TODOS los 105 datasets con theme concatenado
-- Convierte el campo theme de string-concatenado por comas a array JSON valido.
-- WHERE por id (PK de package_extra) => idempotente y seguro.
-- IMPORTANTE: esto NO reindexa Solr. Tras el COMMIT, reindexar los paquetes
--            (ckan search-index rebuild <package_id>) o re-disparar el harvest.

BEGIN;

-- pkg 52b3ed88-7649-4971-ba71-c850c4284aa1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/transporte","http://datos.gob.es/kos/sector-publico/sector/turismo"]' WHERE id = 'a523aeed-719a-4945-a1db-c7c98a1c0162' AND key = 'theme';
-- pkg 241602d4-e64f-4c21-8791-7110f170c43d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '82e29566-1138-4a9f-a448-c2b9d1776a98' AND key = 'theme';
-- pkg 7c90ef10-ba80-4679-8706-7e34b0f76b2a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'de5326c6-c91b-43c6-8641-597941bc282d' AND key = 'theme';
-- pkg bc2a6deb-dae2-42e3-b732-576dcff2ba41
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '12b8fd4e-f543-4bb1-a174-e89a770adfb3' AND key = 'theme';
-- pkg 96814f0c-e68e-4c1b-9ca3-88bd6e6b2460
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '08cefe1f-cdff-4a56-917d-7dc1aa90101d' AND key = 'theme';
-- pkg e8fe533c-0cdc-4a6e-8515-416137257e29
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '779a6889-e1b5-4a3c-b21e-2e97d40a1b68' AND key = 'theme';
-- pkg 44dc4231-b23c-464d-a0b3-709c55ff4571
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '857e4d72-d328-4842-8707-a7a6e4a30b34' AND key = 'theme';
-- pkg 3b0a2f18-5fa4-4c7c-9eb1-c4e71f7e3603
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'b7f1792b-8ffb-491e-b429-085340f35490' AND key = 'theme';
-- pkg 9782150e-b0be-46ec-8fb7-3b2a14ed3c69
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'a1052ac7-fa97-460c-bb03-fb4ad82625b8' AND key = 'theme';
-- pkg e1b1832e-72c3-4a85-aa82-0167493022b7
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '83e7baf7-161d-4319-976b-278f608c6dd4' AND key = 'theme';
-- pkg b37724f9-4476-4ad8-992f-2be94f341d57
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/empleo","http://datos.gob.es/kos/sector-publico/sector/educacion"]' WHERE id = 'b67422df-13db-4210-a3ee-b855005f0b20' AND key = 'theme';
-- pkg 15cacd01-0833-4c24-9ba5-40e2625122e3
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '34945226-ea04-41c5-86ae-7917c36f1eb5' AND key = 'theme';
-- pkg 4821f0bd-d49c-4d6a-8ba2-d28bb16fe71b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '0ed4a4b8-576d-4d80-95d8-2ae79ad44312' AND key = 'theme';
-- pkg cc8770d8-ab3c-4012-8a5e-f2577d8d3d5d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'cac0ce8d-a049-4186-8585-34233789a758' AND key = 'theme';
-- pkg c4edd07e-7b1c-42a3-b671-682cbd079767
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '687a38bc-01b9-476f-8f26-8893fdce1521' AND key = 'theme';
-- pkg f6781e92-b5e5-4f55-b991-6d7f60eef251
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '2ef476d6-1e7e-431a-b01c-172476692c3c' AND key = 'theme';
-- pkg 8cc09fd6-3389-43f1-9776-74e96db72899
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'ddcd0dcb-4953-4830-b927-924a58d46eae' AND key = 'theme';
-- pkg 756a04b0-0407-4160-96cc-32a990f5b2b5
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'acb640e2-f0ed-4099-a14a-7fea30206da1' AND key = 'theme';
-- pkg d7060d12-0fc4-4c6a-b687-865c1e51db7b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '84fee9d3-8ab6-45e0-a9bf-43d6bede2406' AND key = 'theme';
-- pkg 6323a1f0-58c9-4b79-bd51-162658977e6c
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'f57e2c9f-21d5-494b-aa5d-cf8291e234be' AND key = 'theme';
-- pkg 81fb137c-ed13-471a-923d-bda92572c499
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '5e4e70c4-965e-4f44-a6d0-143d8ba30c6f' AND key = 'theme';
-- pkg d0872f97-49fc-4f1f-91e6-3be4dd9a6363
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '4eea7bd1-702d-4e7d-8205-e9a9a62a67bc' AND key = 'theme';
-- pkg ab4c3320-da16-4149-a973-6817ec3cc0cb
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'bed991bf-fcc9-4859-9e8d-45fbff42dfba' AND key = 'theme';
-- pkg e0e2914b-c783-4d89-99c0-6565a561c572
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/ciencia-tecnologia","http://datos.gob.es/kos/sector-publico/sector/cultura-ocio","http://datos.gob.es/kos/sector-publico/sector/demografia","http://datos.gob.es/kos/sector-publico/sector/deporte","http://datos.gob.es/kos/sector-publico/sector/economia","http://datos.gob.es/kos/sector-publico/sector/educacion","http://datos.gob.es/kos/sector-publico/sector/empleo","http://datos.gob.es/kos/sector-publico/sector/energia","http://datos.gob.es/kos/sector-publico/sector/hacienda","http://datos.gob.es/kos/sector-publico/sector/industria","http://datos.gob.es/kos/sector-publico/sector/legislacion-justicia","http://datos.gob.es/kos/sector-publico/sector/medio-ambiente","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/salud","http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/seguridad","http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/transporte","http://datos.gob.es/kos/sector-publico/sector/turismo","http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/vivienda","http://datos.gob.es/kos/sector-publico/sector/comercio"]' WHERE id = 'c7f47703-a631-404e-b371-6a09649630af' AND key = 'theme';
-- pkg d2027de8-3deb-40d3-af12-e0d62018181f
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '25a7e01d-7610-42df-b5a8-80daed5bd3b8' AND key = 'theme';
-- pkg f1c29ba7-8c28-4811-8b93-ea3e44857d60
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '1b7b3c99-e40d-41b1-a270-a0b5c77910d4' AND key = 'theme';
-- pkg 07a1ef3f-1f57-45cb-a2ca-1ef42088ee02
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '03e317d8-7728-412e-9a69-b2e2611c2768' AND key = 'theme';
-- pkg ebaa7c71-9dc9-447a-a5e0-bfefdb83ba71
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'dd0b08c4-54e3-4fc3-a0aa-5aec7fef01f9' AND key = 'theme';
-- pkg 8062e864-dc6d-4a7a-90c1-e1b7bc18fc27
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '785389c0-f8cb-4c80-a8e7-b0303669704c' AND key = 'theme';
-- pkg 20a559f6-19b0-493c-abfb-09a8a9508109
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '887b5744-2072-4d31-9b0e-59e61efd6438' AND key = 'theme';
-- pkg 3f0307e5-0986-47f5-acb1-1855a2ed2195
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '97853b6a-47a8-4fdd-aa47-cd7845cd4dae' AND key = 'theme';
-- pkg 456bedc4-9ee0-445e-aead-061086aacfd9
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'b4e9423f-210c-4b66-b2e5-966e3f224734' AND key = 'theme';
-- pkg 1f8a16e1-11dc-4bb1-8d6b-3ce1c3328b48
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '4de08ad9-fab8-4ef6-8e8b-c4809ca75314' AND key = 'theme';
-- pkg 565b40cc-0392-49be-8914-10381d5f1ed1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '11daa088-f78e-4e6a-85a2-392c286573c6' AND key = 'theme';
-- pkg e5d29c5e-8db9-4d4a-bad6-c91d160c2d6b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '7c17c431-c45c-431a-afe9-7530b0212e5e' AND key = 'theme';
-- pkg 91d18bee-cbad-465b-8ddb-bf532022c166
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '342f75a2-c2ed-4ff7-85c8-0f8f768e3161' AND key = 'theme';
-- pkg f1e0dd60-0ad9-4d78-9dea-c63cf42e039b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '1ec605dd-e032-4a9e-9fe2-149c227cd41e' AND key = 'theme';
-- pkg 02d59b92-4836-4f22-a8a6-2c0954d74bf4
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '60227b3d-57ef-4993-b86b-26e9c830e055' AND key = 'theme';
-- pkg d6df2944-7d08-44fe-8256-8d5e634c0a99
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'c5f6fbd7-9ade-4829-8308-b48798384571' AND key = 'theme';
-- pkg 5eb59323-60ba-46a1-a13f-2cdcb38bd85a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '5f36d0ec-2784-4fbe-a7de-50f749c43817' AND key = 'theme';
-- pkg 946b00f4-f91f-4d8b-b917-88832a5c578a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '9fb3b91d-d560-4292-b88f-38f8c1faed26' AND key = 'theme';
-- pkg 70078944-3ac1-40a7-813c-b4f2667513e2
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '278165ea-9c63-49fa-b375-490e362ec6cb' AND key = 'theme';
-- pkg ab0a4e4a-fe4f-4d4a-9d3d-a8bb02a4c2b3
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'cd64da24-860a-4004-b167-90805ddfc6f3' AND key = 'theme';
-- pkg 0e1437e6-44f1-4ddd-9e7e-92fa93686b97
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '6cfc6191-ac8f-4130-8244-5460ea38dac7' AND key = 'theme';
-- pkg e47b0a8f-211e-45ab-859e-ce53a85fa8aa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '36b0e6f0-eb39-44aa-b27d-b5565215dbaa' AND key = 'theme';
-- pkg bc31e4d9-466f-4f28-a343-a4175b9d4e97
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '1a35e147-4417-4b59-8405-51b980b62bf0' AND key = 'theme';
-- pkg da5e3add-84d3-40f3-9eb1-64b27b1db72c
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'a22469a6-b563-4d0c-9863-3b66ce464cc0' AND key = 'theme';
-- pkg 79eb47f7-bb4d-408c-a12b-c565130b864a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '18c18c5c-ff73-4334-9396-4bcbb3554a43' AND key = 'theme';
-- pkg 0e36bb8f-c580-4dc0-bf98-021b084ab9d0
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '4725956d-cf36-40ea-8434-4d7b1567d375' AND key = 'theme';
-- pkg 0c371791-6dfb-4da8-81c2-c5b90428cc4f
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '4632944a-5fef-4719-8bbc-66425ee676f6' AND key = 'theme';
-- pkg 48127e71-93cd-4bae-ac17-4319720a6e56
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '280ddac9-f3e0-470a-928d-ba0a3a16d80b' AND key = 'theme';
-- pkg 4f3f31ec-2d4a-4cb9-bfc8-a27b30e12244
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '66d41a53-9c4d-4a91-a04e-8590a4b1ef0c' AND key = 'theme';
-- pkg abdc42b8-7a51-4927-8b04-22f7573de382
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'aa8f6da7-678c-4846-87a0-b04437c5d1a1' AND key = 'theme';
-- pkg efeccd49-e77a-49ec-b982-4b76fb531eeb
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '7ec42809-4c41-4d81-960f-8d091449110f' AND key = 'theme';
-- pkg ad652926-fc1f-4ba1-97b8-6178d77e8297
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '539f0cbc-0856-4247-9a3c-ff954f8fa486' AND key = 'theme';
-- pkg 92be23ba-9ed3-41e0-909a-56fa34e91cea
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'e6322174-207e-4103-a68d-c0a2c470f570' AND key = 'theme';
-- pkg f0e34e98-cbea-4e07-9919-3d55744cb80b
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '7bdeb60c-c67c-4582-8d93-b004bcda804c' AND key = 'theme';
-- pkg 7f10d1ea-3354-409a-8038-5fa4475d931d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '8fc74427-7b78-4a19-8217-51b654517ba5' AND key = 'theme';
-- pkg 919fae4e-938b-4698-9b66-fa4de9be17ea
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '97a3d0bc-05d8-4de4-8e5c-93a8276979be' AND key = 'theme';
-- pkg cebf9052-3d87-459b-9262-7b831b6148aa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '373fe573-d407-48ff-99b4-fa638d8907a8' AND key = 'theme';
-- pkg abf5210b-374b-4bc6-b509-c598856c7ef1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'd6bf4125-b7f9-465d-8989-5b177f1838ef' AND key = 'theme';
-- pkg dae156f2-b14b-49aa-ad5f-43fa077c03fa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '8b0143f5-c194-41cf-b9bc-aebbc4f40d1d' AND key = 'theme';
-- pkg 0e5d2a9f-b8e1-4ae7-aa53-6b829b360472
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '26242f73-2c9c-4f14-b616-fa1464d62eee' AND key = 'theme';
-- pkg 041f839a-43e8-40e3-a472-c7c87b2f7d2c
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '41d9c773-eb4c-4286-961f-34d4342fbe67' AND key = 'theme';
-- pkg cea25dce-4370-4401-97fc-6dfdd1250796
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '270d0113-eaac-4a88-9e3d-7512aca9b68f' AND key = 'theme';
-- pkg 95720113-5e22-4ef0-be97-3c9408da9588
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '75492ad8-a365-4034-880d-27de47bd01a3' AND key = 'theme';
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
-- pkg 194d1360-c7fa-4e15-a87b-1da93ddd21b2
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '39dabf7a-ef6f-47ef-abde-fd494c0b0521' AND key = 'theme';
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
-- pkg 925b847c-6754-47db-9d73-93f94afb7c1a
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'bc4915a0-a6a0-4946-be6b-6236b31bdcbc' AND key = 'theme';
-- pkg fa91bde5-6298-47b5-9988-2f3cf7803a52
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '336475d4-cb4c-4f5c-a788-90f27497ea78' AND key = 'theme';
-- pkg f14025c9-13e8-4b7c-b8fd-1699014a5cdb
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '418896fa-ab6a-474b-8a8b-c4261ee15540' AND key = 'theme';
-- pkg 130e8746-5d48-4b5b-8f63-8cca0a062fa5
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/empleo","http://datos.gob.es/kos/sector-publico/sector/educacion"]' WHERE id = '6219ee32-4d15-4f70-b0b0-90aa93ec67a4' AND key = 'theme';
-- pkg 9fbc8c06-e644-4a93-af4f-e507b940f8df
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '8264ba3f-f862-4a32-a077-6a6b824c5d4c' AND key = 'theme';
-- pkg f8a39aa1-e0cc-4821-b4e9-152d2f04811f
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'c6570f23-64a8-4591-866c-deeb7a7ba33c' AND key = 'theme';
-- pkg ed8b7640-98b2-48f2-bcff-1c733320e4b9
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '71f7e3ca-e1b9-4f2e-9a1f-c0912790d364' AND key = 'theme';
-- pkg cda9c12d-fe48-4fd7-bd72-39a1a314b0fa
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'cd6da22b-6041-420d-8e1a-625a80f84ee3' AND key = 'theme';
-- pkg c2ef9afe-ebb1-419e-aa3c-52d158a85ba0
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '591aa4dd-3645-4277-9a21-848e129f1278' AND key = 'theme';
-- pkg 848f26e6-1b76-486b-877c-21e58c666b0e
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '624f0fc6-e2c6-4871-9f9a-238d8ae1fd35' AND key = 'theme';
-- pkg 3938cbf3-af53-42fc-86fc-95a605499954
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '0b5703d7-8e4f-43dc-9906-75f59aa7232a' AND key = 'theme';
-- pkg 4d1dfe3c-cd35-4a16-894e-35ea569ca1f4
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = 'c113affa-51af-433e-bcf4-8efb296355d6' AND key = 'theme';
-- pkg 36513233-e983-493e-9fc2-a85d27e42c37
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '3bc1b429-443a-4511-88b1-77e3aeb76f43' AND key = 'theme';
-- pkg 92ddc748-b7b8-4397-84b8-ceb6ef06f8bb
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '6a8e71bb-8d92-4863-8ecd-654bdf8cf9d8' AND key = 'theme';
-- pkg e482c213-9f04-483b-b17c-00bc34a4c359
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/demografia"]' WHERE id = '67a0ee9c-e938-45ae-b320-e03d3b22522c' AND key = 'theme';
-- pkg 6e8b6b41-1c20-4f8d-bc8d-31ee97163e4d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '6b80d104-ee1c-4475-bdd2-bdd202b5fb3d' AND key = 'theme';
-- pkg 2dc5fc74-b4ed-4c0e-9f75-dc0a0aeaf659
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '6aefbb3e-e5e7-4973-b902-e926185aac16' AND key = 'theme';
-- pkg 50808b96-e31a-4f93-8a4c-a1912abed64d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'c05096ed-757f-4911-a61c-46a0817a2ceb' AND key = 'theme';
-- pkg 2bfeeacd-9e82-40e7-959d-5003e112cbf1
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = '66813122-051c-444d-8bbc-7f94fd453303' AND key = 'theme';
-- pkg 239d7f60-e8d1-4c4e-98af-5ef9b636449d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'f33e0f00-7975-4612-9319-8057766ee0ac' AND key = 'theme';
-- pkg 4f653cae-3028-4c2f-bc9e-41e462b13859
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'eabb09de-bd5e-4101-842d-82bdafbf4617' AND key = 'theme';
-- pkg 2c58d1ff-ab56-46b8-96b0-ff4f6d1e108d
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/economia"]' WHERE id = 'e99dcd2b-94ca-47ed-af56-e26f37bfae24' AND key = 'theme';
-- pkg b98ae1f9-2c8b-4942-a09a-57103c915abc
UPDATE package_extra SET value = '["http://datos.gob.es/kos/sector-publico/sector/ciencia-tecnologia","http://datos.gob.es/kos/sector-publico/sector/vivienda","http://datos.gob.es/kos/sector-publico/sector/sociedad-bienestar","http://datos.gob.es/kos/sector-publico/sector/transporte","http://datos.gob.es/kos/sector-publico/sector/urbanismo-infraestructuras","http://datos.gob.es/kos/sector-publico/sector/empleo","http://datos.gob.es/kos/sector-publico/sector/medio-rural-pesca","http://datos.gob.es/kos/sector-publico/sector/industria","http://datos.gob.es/kos/sector-publico/sector/legislacion-justicia","http://datos.gob.es/kos/sector-publico/sector/educacion","http://datos.gob.es/kos/sector-publico/sector/salud","http://datos.gob.es/kos/sector-publico/sector/economia","http://datos.gob.es/kos/sector-publico/sector/comercio","http://datos.gob.es/kos/sector-publico/sector/deporte","http://datos.gob.es/kos/sector-publico/sector/seguridad","http://datos.gob.es/kos/sector-publico/sector/cultura-ocio","http://datos.gob.es/kos/sector-publico/sector/energia","http://datos.gob.es/kos/sector-publico/sector/demografia","http://datos.gob.es/kos/sector-publico/sector/medio-ambiente","http://datos.gob.es/kos/sector-publico/sector/sector-publico","http://datos.gob.es/kos/sector-publico/sector/turismo","http://datos.gob.es/kos/sector-publico/sector/hacienda"]' WHERE id = 'bbe6b40c-7ef2-45f5-a3f0-d67e2009d5eb' AND key = 'theme';


COMMIT;
