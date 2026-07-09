(function () {
  'use strict';

  /* Figma (nodos 12941:9388 / 12941:9440 "Botonería") pide los iconos de
     estos botones en peso "Light" (Font Awesome 6 PRO), pero el <iframe> de
     la vista lo genera la extensión vendored ckanext-datatablesview (fuera
     de este repo) como documento aparte, con su propio <head> — sólo carga
     el CSS de Font Awesome FREE (que no incluye la cara "Light", exclusiva
     de PRO), así que sin esto los iconos se ven en "Solid" (900), más
     gruesos que en el diseño. La hoja de FA PRO SÍ está disponible en el
     documento padre (inyectada por el servicio externo de metadatos, ver
     "EdatosTheme Configuration" en CLAUDE.md); se reutiliza la misma URL
     aquí para no duplicar/versionar una copia local. Idempotente por "id"
     porque "tryMove" puede reintentar varias veces antes de que la tabla
     esté lista. */
  function ensureFontAwesomeProInIframe(iframeDoc) {
    if (iframeDoc.getElementById('edatos-fontawesome-pro')) {
      return;
    }
    var link = iframeDoc.createElement('link');
    link.id = 'edatos-fontawesome-pro';
    link.rel = 'stylesheet';
    link.href = 'https://estadisticas.arte-consultores.com/apps/assets/css/fontawesome/all.min.css';
    iframeDoc.head.appendChild(link);
  }

  /* Figma (nodos 12937:9102 / 12941:9388 "Botonería") coloca los botones
     "Pantalla completa" e "Incrustar", y también el buscador ("Buscar:"),
     dentro de la MISMA fila que el resto de botones de la tabla (tabla,
     copiar, ocultar columnas, descargar, refrescar, imprimir, compartir).
     "Pantalla completa"/"Incrustar" se renderizan en el documento padre
     (snippet resource_view.html), mientras que ".dt-buttons" la genera en
     tiempo de ejecución la extensión vendored ckanext-datatablesview dentro
     del <iframe> de la vista (fuera de este repo) — son documentos
     distintos, así que no se pueden unir con CSS. Se resuelve moviendo (no
     clonando, para conservar los listeners ya enganchados por los módulos
     "resource-view-embed"/enlace nativo) los nodos reales al DOM del iframe
     una vez que su tabla ha inicializado. El buscador (".dataTables_filter")
     en cambio ya vive en ese mismo documento del iframe, como hermano de
     ".dt-buttons" — a ese solo hace falta moverlo dentro con un
     "appendChild" normal, sin "adoptNode". */
  function moveButtonsIntoDtButtons(iframeDoc, buttons, filtersContainer) {
    var dtButtons = iframeDoc.querySelector('.dt-buttons.btn-group');
    if (!dtButtons) {
      return false;
    }
    ensureFontAwesomeProInIframe(iframeDoc);
    /* Ancla fija (el primer botón original, p.ej. "tabla") para que los
       botones insertados conserven su orden relativo en vez de invertirse
       por reinsertarse cada uno en la cabeza. */
    var anchor = dtButtons.firstChild;

    /* "Agregar Filtro" (".resource-view-filters", documento padre) se
       inserta ANTES de Fullscreen/Incrustar para que quede como primer
       elemento de la fila, igual que en Figma (nodo 12937:9102
       "Botonería"): [Agregar Filtro] ... resto de botones. */
    if (filtersContainer) {
      dtButtons.insertBefore(iframeDoc.adoptNode(filtersContainer), anchor);
    }

    buttons.forEach(function (btn) {
      var adopted = iframeDoc.adoptNode(btn);
      dtButtons.insertBefore(adopted, anchor);
    });

    /* El buscador ("Buscar:") vive en ".dataTables_filter", hermano de
       ".dt-buttons" dentro del MISMO documento (el iframe), no hace falta
       "adoptNode" aquí — es un simple "appendChild" al final del grupo,
       tal como lo coloca Figma (último elemento de la fila). */
    var filterWrap = iframeDoc.querySelector('.dataTables_filter');
    if (filterWrap) {
      dtButtons.appendChild(filterWrap);
    }

    return true;
  }

  /* "Agregar Filtro" (".resource-view-filters") lo genera el módulo JS de
     CKAN core "resource-view-filters" (fuera de este repo) con select2 (v4,
     adaptador "AttachBody") sin "dropdownParent" — el panel flotante de
     opciones se ancla siempre a "document.body" del documento donde corre
     ese código (el documento padre). Al mover el control al <iframe>,
     select2 sigue centrando el panel con "jQuery.offset()" del propio
     control (coordenadas relativas al documento del iframe) pero lo inserta
     en el <body> del documento padre — coordenadas de documentos distintos,
     así que el panel aparece desconectado del control (verificado en el
     navegador: aparecía en la esquina superior izquierda de la página).
     Se corrige sin tocar el JS de core envolviendo "jQuery.fn.select2": si
     el elemento ya vive dentro del iframe en el momento de inicializarse,
     se le fuerza "dropdownParent" al <body> de ESE MISMO documento, para
     que las coordenadas sean comparables. No afecta a ningún otro uso de
     select2 del sitio (sólo entra en juego cuando el elemento vive dentro
     de este iframe concreto).
     Límite conocido: si la URL ya trae filtros activos ("?filters=..."),
     sus desplegables de valor se inicializan durante el arranque del módulo
     de CKAN core, antes de que este script mueva ".resource-view-filters"
     al iframe — en ese caso el "dropdownParent" ya quedó fijado al
     documento padre y el parche no llega a tiempo para ese desplegable en
     concreto. Los filtros añadidos después de la carga (el caso normal) sí
     quedan cubiertos, porque el elemento ya está dentro del iframe cuando
     se llama a ".select2()". */
  function patchSelect2ForIframes(jq) {
    if (!jq || !jq.fn || !jq.fn.select2 || jq.fn.select2.__edatosIframeAware) {
      return;
    }
    var original = jq.fn.select2;
    function patched(options) {
      var el = this[0];
      if (el && options !== null && typeof options === 'object' &&
          el.ownerDocument !== document) {
        return original.call(this, jq.extend({}, options, {
          dropdownParent: jq(el.ownerDocument.body)
        }));
      }
      return original.apply(this, arguments);
    }
    patched.__edatosIframeAware = true;
    jq.fn.select2 = patched;
  }

  document.addEventListener('DOMContentLoaded', function () {
    /* Este bundle ("edatostheme_js") se carga ANTES que "jquery.js" en el
       <head> (orden de webassets, fuera de nuestro control), así que
       aplicar el parche a nivel superior del IIFE (al ejecutarse el propio
       script) se hacía con "window.jQuery" aún sin definir y quedaba sin
       efecto silenciosamente. Aplicarlo aquí, dentro de "DOMContentLoaded",
       garantiza que todos los <script> síncronos anteriores en el documento
       (jQuery incluido) ya se han ejecutado, sin importar el orden de
       registro de los listeners de ese evento. */
    patchSelect2ForIframes(window.jQuery);

    var actions = document.querySelector('.resource-view .actions');
    var filtersContainer = document.querySelector('.resource-view-filters');
    var iframe = document.querySelector('iframe[data-module="data-viewer"]');

    if (!actions || !iframe) {
      return;
    }

    var buttons = Array.prototype.slice.call(
      actions.querySelectorAll('.resource-view-toolbar-btn')
    );
    if (buttons.length === 0) {
      return;
    }

    var moved = false;

    function tryMove() {
      if (moved) {
        return;
      }
      var iframeDoc;
      try {
        iframeDoc = iframe.contentDocument;
      } catch (err) {
        return;
      }
      if (iframeDoc && moveButtonsIntoDtButtons(iframeDoc, buttons, filtersContainer)) {
        moved = true;
        clearInterval(poll);
      }
    }

    iframe.addEventListener('load', tryMove);

    /* La tabla (DataTables Buttons) puede tardar en inicializar tras el
       "load" del iframe; se reintenta durante unos segundos por si acaso. */
    var attempts = 0;
    var poll = setInterval(function () {
      attempts += 1;
      tryMove();
      if (attempts >= 20) {
        clearInterval(poll);
      }
    }, 250);
  });
})();
