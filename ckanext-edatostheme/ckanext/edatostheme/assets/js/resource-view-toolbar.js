(function () {
  'use strict';

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
  function moveButtonsIntoDtButtons(iframeDoc, buttons) {
    var dtButtons = iframeDoc.querySelector('.dt-buttons.btn-group');
    if (!dtButtons) {
      return false;
    }
    /* Ancla fija (el primer botón original, p.ej. "tabla") para que los
       botones insertados conserven su orden relativo (Fullscreen, Incrustar)
       en vez de invertirse por reinsertarse cada uno en la cabeza. */
    var anchor = dtButtons.firstChild;
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

  document.addEventListener('DOMContentLoaded', function () {
    var actions = document.querySelector('.resource-view .actions');
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
      if (iframeDoc && moveButtonsIntoDtButtons(iframeDoc, buttons)) {
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
