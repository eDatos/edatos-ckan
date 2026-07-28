(function () {
  'use strict';

  /* Prototipo -- ver docs/theming-resource-view-buttons.md, "Prototipo:
     toolbar renderizada dentro del iframe". Sustituye por completo a
     "resource-view-toolbar.js" (eliminado): la toolbar ya no vive en el
     documento padre y se traslada al iframe, sino que se renderiza
     directamente dentro de él (templates_priority/datatables/datatables_view.html),
     así que este fichero no necesita "adoptNode", ni distinguir "documento
     padre" de "documento del iframe", ni reintentar tras cada recarga
     interna del iframe: cada recarga es simplemente una carga nueva de ESTA
     página, que vuelve a ejecutar este script y sus módulos "ckan.module"
     desde cero. */

  /* "edatostheme_js" (este bundle) se carga ANTES que "jquery.js"/"main.js"
     en el documento (orden de webassets, fuera de nuestro control -- mismo
     problema ya documentado en la versión anterior de este fichero para
     "patchSelect2ForIframes"): "ckan.module" (la función de registro, que
     define "main.js") todavía no existe cuando el intérprete llega aquí en
     el nivel superior del script, así que llamarla directamente revienta
     con un TypeError -- silenciosamente para el usuario, visible solo en la
     consola -- y esa excepción aborta el resto de este bloque de script.
     Registrar el módulo dentro de "DOMContentLoaded" lo evita: por orden de
     listeners sobre el mismo evento (el de registro, no el de declaración
     en el árbol), el nuestro se ejecuta ANTES que el de "main.js" que
     escanea el documento en busca de "data-module" y arranca cada módulo ya
     registrado -- que es justo el que necesitamos que corra primero. */
  document.addEventListener('DOMContentLoaded', function () {
    /* Builds the "Add Filter" trigger + flyout panel and returns the
       container element ready to be inserted into ".dt-buttons". Same UI
       and behaviour as the previous "edatos-inline-filter-panel" ckan.module
       (checkbox list per field, values fetched from datastore_search, state
       shared with CKAN core via "ckan.views.filters") -- only the wiring
       changed: this is no longer a separate module bound to its own
       "data-module" element, since it is now created entirely in JS and
       handed to ".dt-buttons" directly (see "setUpToolbar" below), instead
       of being pre-rendered by Jinja and relocated later.

       This still needs a real DOM container inserted by hand (not the
       DataTables Buttons API): a Buttons button is a single element, and
       this widget is a button PLUS an anchored flyout panel with its own
       state -- there is no native DataTables/CKAN equivalent to register it
       through. "Fullscreen"/"Embed" below, which ARE simple one-shot
       actions, use the real Buttons API instead. */
    function buildFilterPanel(resourceId, fields, translate) {
      var container = document.createElement('div');
      container.className = 'resource-view-filters';

      var toggleButton = document.createElement('a');
      toggleButton.className = 'btn btn-primary';
      toggleButton.href = '#';
      toggleButton.textContent = translate('Add Filter');
      container.appendChild(toggleButton);

      var panel = document.createElement('div');
      panel.className = 'edatos-filter-panel';
      panel.hidden = true;
      container.appendChild(panel);

      var state = { field: null, distinctValues: null };
      var outsideClickHandler = null;
      var escapeHandler = null;

      function buildClearRow(onClear) {
        var clear = document.createElement('div');
        clear.className = 'edatos-filter-panel-clear';
        clear.textContent = 'Eliminar filtro';
        clear.addEventListener('click', function (evt) {
          evt.stopPropagation();
          onClear();
        });
        return clear;
      }

      function activeValues(field) {
        return (window.ckan.views.filters.get(field) || []).slice();
      }

      function hasActiveFilter(field) {
        return activeValues(field).length > 0;
      }

      /* Marcar/desmarcar una casilla de VALOR aplica el filtro al instante:
         "ckan.views.filters.set()/.unset()" navegan de inmediato en cuanto
         detectan un cambio real. Esa navegación es la del propio documento
         del iframe (no la del padre), así que solo se recarga la tabla,
         igual que ya hace el botón nativo de alternar vista. */
      function toggleValue(field, value) {
        var current = activeValues(field);
        var idx = current.indexOf(value);
        if (idx === -1) {
          current.push(value);
        } else {
          current.splice(idx, 1);
        }
        if (current.length > 0) {
          window.ckan.views.filters.set(field, current);
        } else {
          window.ckan.views.filters.unset(field);
        }
      }

      function openFieldList() {
        state.field = null;
        panel.hidden = false;
        container.classList.add('edatos-filter-open');
        renderFieldList();
        bindCloseOnOutsideInteraction();
      }

      function openValueList(field) {
        state.field = field;
        state.distinctValues = null;
        renderValueList();
        fetchDistinctValues(field);
      }

      function closePanel() {
        panel.hidden = true;
        container.classList.remove('edatos-filter-open');
        state.field = null;
        unbindCloseOnOutsideInteraction();
      }

      function renderFieldList() {
        panel.innerHTML = '';
        var list = document.createElement('ul');
        list.className = 'edatos-filter-panel-list';
        fields.forEach(function (field) {
          var li = document.createElement('li');
          li.className = 'edatos-filter-panel-item' +
            (hasActiveFilter(field) ? ' edatos-filter-panel-item--checked' : '');
          li.textContent = field;
          /* "stopPropagation()" imprescindible: "openValueList" reconstruye
             el panel de forma SÍNCRONA ("panel.innerHTML = ''") dentro de
             este mismo handler, desconectando este "li" del árbol antes de
             que el clic termine de burbujear -- sin esto, el listener de
             "clic fuera" (en "document") trataría el clic como "fuera del
             panel" y lo cerraría de inmediato. */
          li.addEventListener('click', function (evt) {
            evt.stopPropagation();
            openValueList(field);
          });
          list.appendChild(li);
        });
        panel.appendChild(list);
        panel.appendChild(buildClearRow(function () {
          var current = window.ckan.views.filters.get();
          Object.keys(current).forEach(function (f) {
            window.ckan.views.filters.unset(f);
          });
        }));
      }

      function renderValueList() {
        panel.innerHTML = '';
        var back = document.createElement('div');
        back.className = 'edatos-filter-panel-back';
        back.textContent = state.field;
        back.addEventListener('click', function (evt) {
          evt.stopPropagation();
          openFieldList();
        });
        panel.appendChild(back);

        var list = document.createElement('ul');
        list.className = 'edatos-filter-panel-list';
        panel.appendChild(list);
        renderValueItems(list);

        panel.appendChild(buildClearRow(function () {
          window.ckan.views.filters.unset(state.field);
        }));
      }

      function renderValueItems(list) {
        list.innerHTML = '';
        if (state.distinctValues === null) {
          var loading = document.createElement('li');
          loading.className = 'edatos-filter-panel-loading';
          loading.textContent = 'Cargando...';
          list.appendChild(loading);
          return;
        }
        if (state.distinctValues.length === 0) {
          var empty = document.createElement('li');
          empty.className = 'edatos-filter-panel-empty';
          empty.textContent = 'Sin valores';
          list.appendChild(empty);
          return;
        }
        var checkedValues = activeValues(state.field);
        state.distinctValues.forEach(function (value) {
          var li = document.createElement('li');
          li.className = 'edatos-filter-panel-item' +
            (checkedValues.indexOf(value) !== -1 ? ' edatos-filter-panel-item--checked' : '');
          li.textContent = value;
          li.addEventListener('click', function (evt) {
            evt.stopPropagation();
            toggleValue(state.field, value);
          });
          list.appendChild(li);
        });
      }

      function fetchDistinctValues(field) {
        var url = window.ckan.url('/api/3/action/datastore_search');
        window.jQuery.getJSON(url, {
          resource_id: resourceId,
          fields: field,
          distinct: true,
          limit: 100,
          sort: field,
          include_total: false
        }).done(function (data) {
          if (state.field !== field) {
            return;
          }
          state.distinctValues = (data.result.records || []).map(function (record) {
            return record[field];
          });
          var list = panel.querySelector('.edatos-filter-panel-list');
          if (list) {
            renderValueItems(list);
          }
        }).fail(function () {
          if (state.field !== field) {
            return;
          }
          state.distinctValues = [];
          var list = panel.querySelector('.edatos-filter-panel-list');
          if (list) {
            renderValueItems(list);
          }
        });
      }

      function bindCloseOnOutsideInteraction() {
        outsideClickHandler = function (evt) {
          if (!panel.hidden && !container.contains(evt.target)) {
            closePanel();
          }
        };
        escapeHandler = function (evt) {
          if (evt.key === 'Escape' && !panel.hidden) {
            closePanel();
          }
        };
        document.addEventListener('click', outsideClickHandler);
        document.addEventListener('keydown', escapeHandler);
      }

      function unbindCloseOnOutsideInteraction() {
        if (outsideClickHandler) {
          document.removeEventListener('click', outsideClickHandler);
          outsideClickHandler = null;
        }
        if (escapeHandler) {
          document.removeEventListener('keydown', escapeHandler);
          escapeHandler = null;
        }
      }

      toggleButton.addEventListener('click', function (evt) {
        evt.preventDefault();
        evt.stopPropagation();
        if (panel.hidden) {
          openFieldList();
        } else {
          closePanel();
        }
      });

      return container;
    }

    /* ".dt-buttons.btn-group" (extensión Buttons de DataTables, vendor
       ckan/ckanext/datatablesview -- CKAN core) ya expone una API pública
       para añadir botones a un grupo ya existente ("button().add()", ver
       "assets/vendor/DataTables/datatables.js"). Usarla (en vez de mover
       nodos ya renderizados con "insertBefore") deja que "Pantalla
       completa"/"Incrustar" sean botones DataTables de verdad, con el mismo
       ciclo de vida que "Copiar"/"Imprimir" -- ya no son nodos ajenos que la
       propia librería desconoce.

       El vendor también publica un evento propio de "ya terminé de
       inicializar la tabla" ("datatablesview:init-complete", dentro de
       "initComplete", vía "sandbox.publish", el mismo mecanismo de pub/sub
       que ya usa "data-viewer.js" de CKAN core) -- pero ESE evento solo se
       dispara tras el primer "draw" con datos ya resueltos. Si el "ajax" de
       "datastore_search" falla (comprobado en el entorno real: un recurso
       con la petición inicial fallida, "DataTables warning ... Ajax error",
       tn/7), "initComplete" nunca llega a ejecutarse y con él tampoco
       nuestro evento -- los botones propios no aparecerían nunca, aunque la
       fila ".dt-buttons" (que la extensión Buttons construye de forma
       SÍNCRONA, dentro de la misma llamada a ".DataTable()", sin depender
       del resultado del "ajax") sí exista. Por eso se sigue observando la
       aparición de ".dt-buttons.btn-group" en el DOM (con un
       "MutationObserver" que se desconecta en cuanto lo encuentra, no un
       poll indefinido) en vez de fiarse de ese evento: es la única señal
       que no depende de que la carga de datos llegue a buen puerto. */
    window.ckan.module('edatos-inline-resource-toolbar', function ($) {
      return {
        options: {
          resourceId: null,
          fields: [],
          filterable: false
        },

        initialize: function () {
          var self = this;

          /* Esta misma plantilla se sirve tal cual cuando se visita la URL
             de la vista directamente (enlace compartido, o el propio botón
             "Pantalla completa", "target=_blank") -- sin distinción de
             código entre "estoy dentro de un iframe" y "soy la página de
             nivel superior". Solo se conserva esta clase para que
             "custom.css" pueda dar aire extra entre la botonera y el borde
             superior del navegador SOLO en ese caso (en el <iframe> real,
             ese margen ya lo da el layout de la página que lo envuelve). */
          if (window.self === window.top) {
            document.documentElement.classList.add('edatos-standalone-dt-view');
          }

          if (self.setUpToolbar()) {
            return;
          }
          var observer = new MutationObserver(function () {
            if (self.setUpToolbar()) {
              observer.disconnect();
            }
          });
          observer.observe(document.body, { childList: true, subtree: true });
        },

        /* Devuelve "true" en cuanto ".dt-buttons.btn-group" existe y ya se
           han añadido los botones propios (fin de la espera), "false" si
           todavía no existe (el observer de "initialize" reintentará). */
        setUpToolbar: function () {
          var self = this;
          var dtButtons = document.querySelector('.dt-buttons.btn-group');
          if (!dtButtons) {
            return false;
          }
          var dt = $('#dtprv').DataTable({ retrieve: true });

          /* Orden crítico: "Agregar Filtro" primero, "Pantalla completa"
             después -- el CSS existente (custom.css, ".resource-view-filters
             + .btn.resource-view-toolbar-btn") empuja el SEGUNDO grupo
             (Pantalla completa/Incrustar/botones nativos/buscador) hacia el
             borde derecho vía "margin-left:auto" en el elemento
             inmediatamente posterior a ".resource-view-filters". Por eso se
             añaden "Pantalla completa"/"Incrustar" en las posiciones 0/1
             (antes de los 7 botones nativos) y el contenedor de "Agregar
             Filtro" se inserta el último, como PRIMER hijo de ".dt-buttons"
             -- así queda inmediatamente antes de "Pantalla completa" y el
             selector de hermano adyacente sigue matcheando. */
          dt.button().add(0, {
            text: '<i class="fa fa-up-right-and-down-left-from-center"></i> ' + self._('Fullscreen'),
            className: 'btn btn-default resource-view-toolbar-btn',
            action: function () {
              window.open(window.location.href, '_blank', 'noopener');
            }
          });

          dt.button().add(1, {
            text: '<i class="fa fa-object-group"></i> ' + self._('Embed'),
            className: 'btn btn-default resource-view-toolbar-btn',
            action: function () {
              /* Reutiliza el módulo "resource-view-embed" de CKAN core tal
                 cual (ckan/public/base/javascript/modules/resource-view-embed.js):
                 solo necesita que exista en el documento un elemento con
                 "data-module=\"resource-view-embed\"" -- él mismo reubica su
                 modal a <body> y gestiona el textarea de código embed. No
                 hace falta reimplementar nada de eso, solo disparar su clic
                 desde aquí en vez de que sea un botón visible por sí mismo. */
              var trigger = document.querySelector('[data-module="resource-view-embed"]');
              if (trigger) {
                trigger.click();
              }
            }
          });

          dtButtons = document.querySelector('.dt-buttons.btn-group');
          if (self.options.filterable) {
            var filterContainer = buildFilterPanel(
              self.options.resourceId,
              self.options.fields,
              function (text) { return self._(text); }
            );
            dtButtons.insertBefore(filterContainer, dtButtons.firstChild);
          }

          /* El buscador ("Buscar:") de DataTables (".dataTables_filter") no
             es un botón -- es una "feature" propia del layout ("f" en el
             "dom" string del vendor), sin API para registrarlo dentro de
             ".dt-buttons". Se mueve a mano, como último elemento de la fila
             (igual que en Figma), tal y como ya hacía la versión anterior de
             este módulo. */
          var filterWrap = document.querySelector('.dataTables_filter');
          if (filterWrap) {
            dtButtons.appendChild(filterWrap);
          }
          return true;
        }
      };
    });
  });
})();
