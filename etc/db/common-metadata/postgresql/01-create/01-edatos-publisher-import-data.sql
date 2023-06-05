/*
 *NOTA. Esta propiedad es necesaria para el proyecto PUBLISHER. Se decide centralizar en CKAN el cambio. 
 */
insert into TB_DATA_CONFIGURATIONS (ID,VERSION,SYSTEM_PROPERTY,CONF_KEY,CONF_VALUE,EXTERNALLY_PUBLISHED) values(GET_NEXT_SEQUENCE_VALUE('DATA_CONFIGURATIONS'),1,true,
'edatos.ckan.url.base','FILL_ME',false);
UPDATE TB_SEQUENCES SET SEQUENCE_NEXT_VALUE = SEQUENCE_NEXT_VALUE + 1 WHERE SEQUENCE_NAME = 'DATA_CONFIGURATIONS';

/*
NOTA. Esta propiedad es necesaria para el proyecto PUBLISHER. Se decide centralizar en CKAN el cambio.
Configuración para Entorno de demo:
insert into TB_DATA_CONFIGURATIONS (ID,VERSION,SYSTEM_PROPERTY,CONF_KEY,CONF_VALUE,EXTERNALLY_PUBLISHED) values(GET_NEXT_SEQUENCE_VALUE('DATA_CONFIGURATIONS'),1,true,
'edatos.ckan.url.base','https://estadisticas.arte-consultores.com/catalogo',false);
UPDATE TB_SEQUENCES SET SEQUENCE_NEXT_VALUE = SEQUENCE_NEXT_VALUE + 1 WHERE SEQUENCE_NAME = 'DATA_CONFIGURATIONS';
*/