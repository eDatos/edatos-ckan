(function () {
  'use strict';

  /* NOTA (prototipo, ver docs/theming-resource-view-buttons.md, "Prototipo:
     toolbar renderizada dentro del iframe"): este fichero contenía además la
     fusión de "Pantalla completa"/"Agregar Filtro" con ".dt-buttons"
     (adoptNode + MutationObserver + polling cross-iframe) y el parche de
     select2 para el flujo nativo de filtros. Todo eso queda sustituido, para
     "datatables_view", por "resource-view-inline-toolbar.js" +
     "templates_priority/datatables/datatables_view.html" (renderizan la
     toolbar directamente DENTRO del documento del iframe, sin necesidad de
     mover nodos entre documentos). Este fichero conserva únicamente la POC de
     scrollX (ver "specs/fix-resource-view-datatable-scrollx-poc.md"), que no
     tiene relación con el problema de la toolbar y sigue necesitando
     ejecutarse desde el documento PADRE porque es quien controla el
     <iframe>. "Incrustar" queda fuera de alcance de este prototipo -- ver
     nota en resource_view.html -- y se sigue renderizando sin fusionar en
     ".actions", en el documento padre, sin este script. */

  /* Prueba de concepto acotada a UN ÚNICO recurso -- ver
     "specs/investigacion-scroll-lateral-resource-view-datatable.md". Este
     mismo módulo se aplica a TODAS las vistas "datatables_view" del portal;
     desactivar el colapso responsive (el icono "+" que oculta columnas en
     pantallas estrechas) en recursos con muchas columnas o en móvil
     empeoraría esas otras tablas, así que el cambio se acota a este
     "resourceId" mientras se valida, en vez de generalizarse de entrada. */
  var EDATOS_SCROLLX_POC_RESOURCE_ID = 'bfe4de48-d84f-4578-a991-728770bf71cb';

  /* El vendor (ckan/ckanext/datatablesview) inicializa DataTables con
     "responsive:true" y sin "scrollX" (solo "scrollY:400" para el scroll
     vertical) -- ver la investigación referenciada arriba. Con esa
     configuración, DataTables jamás deja que la tabla desborde el ancho
     disponible: en vez de un scroll horizontal, la extensión Responsive
     oculta columnas de baja prioridad tras el icono "+" de cada fila,
     recalculando en cada resize/redraw. No hay overflow horizontal al que
     aplicarle un estilo de scrollbar -- hay que reconfigurar la propia
     instancia. DataTables no admite cambiar "responsive"/"scrollX" sobre una
     tabla ya inicializada: solo destruyéndola y reconstruyéndola con otras
     opciones ("destroy:true" + nuevo objeto de configuración), reutilizando
     el resto de "oInit" (columnas, "ajaxurl", "scrollY", botones...) tal
     cual lo dejó el vendor, para no perder nada de lo ya configurado. */
  function enableRealScrollXForResource(iframeDoc, iframeWin, resourceId) {
    if (resourceId !== EDATOS_SCROLLX_POC_RESOURCE_ID) {
      return;
    }
    /* Idempotente por documento de iframe (no por "resourceId"): cada
       recarga interna del iframe (alternar tabla/lista) crea un documento
       nuevo, que necesita su propia reconfiguración. */
    if (iframeDoc.__edatosScrollXApplied) {
      return;
    }
    var jq = iframeWin.jQuery;
    if (!jq || !jq.fn || !jq.fn.dataTable) {
      return;
    }
    var table = jq('.dataTable', iframeDoc).eq(0);
    if (!table.length || !jq.fn.dataTable.isDataTable(table[0])) {
      /* Todavía no ha terminado de inicializarse -- el llamante reintenta en
         el siguiente tick del poll de respaldo. */
      return;
    }
    /* "table.DataTable().settings()[0]" devuelve "undefined" de forma
       intermitente en esta versión de DataTables (comprobado en consola:
       unas veces da el objeto de ajustes real, otras no) -- en cambio
       "$.fn.dataTable.settings" (el array plano y global de instancias
       activas, sin pasar por el envoltorio "Api" de "settings()") funcionó
       de forma consistente en todas las pruebas. Se busca ahí la entrada
       cuyo "nTable" (el <table> real que gestiona, propiedad interna
       estándar de DataTables) sea el nodo actual. */
    var allSettings = jq.fn.dataTable.settings;
    var settings = null;
    for (var i = 0; i < allSettings.length; i += 1) {
      if (allSettings[i].nTable === table[0]) {
        settings = allSettings[i];
        break;
      }
    }
    if (!settings) {
      return;
    }
    iframeDoc.__edatosScrollXApplied = true;
    var config = jq.extend(true, {}, settings.oInit);
    config.responsive = false;
    config.scrollX = true;
    config.destroy = true;
    var newDt = table.DataTable(config);
    /* Ninguna columna trae "visible:false" en "oInit.columns" (confirmado
       inspeccionando la config real) -- las que aparecían ocultas antes de
       este cambio lo estaban por el estado guardado de "stateSave" (activo
       en el propio "oInit"), no por configuración. Se fuerzan visibles
       aquí, ignorando ese estado guardado, para que el ancho real de la
       tabla (y por tanto el scroll horizontal) incluya siempre todas las
       columnas con datos. Se excluye la columna auxiliar sin datos que usa
       Responsive para la fila de detalle (className "none", sin nombre) --
       ya no cumple ninguna función con "responsive:false". */
    newDt.columns().every(function () {
      var header = this.header();
      if (header && header.className === 'none') {
        return;
      }
      this.visible(true, false);
    });
    newDt.columns.adjust();
  }

  document.addEventListener('DOMContentLoaded', function () {
    var iframe = document.querySelector('iframe[data-module="data-viewer"]');
    if (!iframe) {
      return;
    }

    var currentResourceIdMatch = window.location.pathname.match(/\/resource\/([0-9a-fA-F-]{36})/);
    var currentResourceId = currentResourceIdMatch ? currentResourceIdMatch[1] : null;

    function getIframeDoc() {
      try {
        return iframe.contentDocument;
      } catch (err) {
        return null;
      }
    }

    iframe.addEventListener('load', function () {
      var iframeDoc = getIframeDoc();
      if (iframeDoc) {
        enableRealScrollXForResource(iframeDoc, iframe.contentWindow, currentResourceId);
      }
    });

    /* Poll de respaldo (por si "load" ya disparó antes de registrar este
       listener, o DataTables tardara más en inicializar que el propio
       evento "load" del iframe) -- sin límite de intentos: el usuario puede
       alternar tabla/lista tantas veces como quiera y cada clic dispara una
       recarga interna nueva que hay que volver a atender. */
    setInterval(function () {
      var iframeDoc = getIframeDoc();
      if (iframeDoc) {
        enableRealScrollXForResource(iframeDoc, iframe.contentWindow, currentResourceId);
      }
    }, 250);
  });
})();
