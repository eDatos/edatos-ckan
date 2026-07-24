(function () {
  'use strict';

  /* Prototipo -- ver docs/theming-resource-view-buttons.md, "Prototipo:
     toolbar renderizada dentro del iframe". Sustituye, para "datatables_view",
     a "resource-view-toolbar.js": la toolbar ya no vive en el documento padre
     y se traslada al iframe, sino que se renderiza directamente dentro de él
     (templates_priority/datatables/datatables_view.html), así que este
     fichero no necesita "adoptNode", ni distinguir "documento padre" de
     "documento del iframe", ni reintentar tras cada recarga interna del
     iframe: cada recarga es simplemente una carga nueva de ESTA página, que
     vuelve a ejecutar este script y sus módulos "ckan.module" desde cero. */

  /* "edatostheme_js" (este bundle) se carga ANTES que "jquery.js"/"main.js"
     en el documento (orden de webassets, fuera de nuestro control -- mismo
     problema ya documentado en la versión anterior de este fichero para
     "patchSelect2ForIframes"): "ckan.module" (la función de registro, que
     define "main.js") todavía no existe cuando el intérprete llega aquí en
     el nivel superior del script, así que llamarla directamente revienta
     con un TypeError -- silenciosamente para el usuario, visible solo en la
     consola -- y esa excepción aborta el resto de este bloque de script,
     incluido el registro del segundo módulo ("edatos-inline-filter-panel")
     que le sigue. Registrar ambos módulos dentro de "DOMContentLoaded" lo
     evita: por orden de listeners sobre el mismo evento (el de registro,
     no el de declaración en el árbol), el nuestro se ejecuta ANTES que el
     de "main.js" que escanea el documento en busca de "data-module" y
     arranca cada módulo ya registrado -- que es justo el que necesitamos
     que corra primero. */
  document.addEventListener('DOMContentLoaded', function () {
    /* ".dt-buttons.btn-group" lo crea en tiempo de ejecución la extensión
       vendored ckan/ckanext/datatablesview al inicializar DataTables --
       puede no existir todavía cuando corre este módulo, así que se
       reintenta con un MutationObserver hasta que aparezca. A diferencia de
       la versión anterior, esto ya no cruza ningún documento:
       "insertBefore"/"appendChild" bastan (no hace falta "adoptNode",
       reservado para mover nodos ENTRE documentos distintos). */
    window.ckan.module('edatos-inline-resource-toolbar', function ($) {
      return {
        initialize: function () {
          var wrapper = this.el[0];
          var children = Array.prototype.slice.call(wrapper.children);

          /* Esta misma plantilla se sirve tal cual cuando se visita la URL
             de la vista directamente (enlace compartido, o el propio botón
             "Pantalla completa", "target=_blank") -- sin distinción de
             código entre "estoy dentro de un iframe" y "soy la página de
             nivel superior", a diferencia de la versión anterior
             (resource-view-toolbar.js, rama "window.self === window.top").
             Solo se conserva esta clase para que "custom.css" pueda dar
             aire extra entre la botonera y el borde superior del navegador
             SOLO en ese caso (en el <iframe> real, ese margen ya lo da el
             layout de la página que lo envuelve). */
          if (window.self === window.top) {
            document.documentElement.classList.add('edatos-standalone-dt-view');
          }

          function tryInsert() {
            var dtButtons = document.querySelector('.dt-buttons.btn-group');
            if (!dtButtons) {
              return false;
            }
            /* Ancla fija (el primer botón nativo, p.ej. "tabla"), capturada
               UNA vez antes del bucle -- insertar varios nodos con
               "insertBefore(nodo, dtButtons.firstChild)" dentro del mismo
               bucle invertiría su orden si se releyera "firstChild" en cada
               iteración. */
            var anchor = dtButtons.firstChild;
            children.forEach(function (child) {
              dtButtons.insertBefore(child, anchor);
            });
            wrapper.parentNode.removeChild(wrapper);

            /* El buscador ("Buscar:") vive en ".dataTables_filter", hermano
               de ".dt-buttons" dentro del MISMO documento -- ya no hace
               falta "adoptNode" (nunca hizo falta para este elemento en
               concreto, ver comentario histórico en la versión anterior de
               este fichero), solo un "appendChild" al final del grupo, tal
               como lo coloca Figma (último elemento de la fila). */
            var filterWrap = document.querySelector('.dataTables_filter');
            if (filterWrap) {
              dtButtons.appendChild(filterWrap);
            }
            return true;
          }

          if (tryInsert()) {
            return;
          }
          var observer = new MutationObserver(function () {
            if (tryInsert()) {
              observer.disconnect();
            }
          });
          observer.observe(document.body, { childList: true, subtree: true });
        }
      };
    });

    /* Panel de checkboxes de "Agregar Filtro" -- misma UI e interacción que
       la versión anterior (setupCustomFilterPanel en
       resource-view-toolbar.js), pero sin la complejidad que exigía vivir a
       caballo entre dos documentos: nada de "ownerDocument"/"currentDoc()"
       releído en cada operación, nada de reenganchar listeners tras un
       "adoptNode" (aquí no hay ninguno), y el cierre "clic fuera"/Escape se
       engancha sobre "document" sin más -- siempre es el documento
       correcto, porque este panel nunca cambia de documento. El estado de
       los filtros sigue viviendo en la misma API pública de CKAN core
       ("ckan.views.filters", cargada aquí vía "{% asset 'base/view-filters'
       %}" en la plantilla), así que la URL resultante es idéntica a la que
       ya producía el flujo por defecto -- salvo que ahora es la URL del
       propio iframe la que navega (mismo mecanismo que ya usa hoy el botón
       nativo "Tabla/Lista" del vendor). */
    window.ckan.module('edatos-inline-filter-panel', function ($) {
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

    return {
      options: {
        resourceId: null,
        fields: []
      },

      initialize: function () {
        var self = this;
        self.container = self.el[0];
        self.toggleButton = self.container.querySelector('a.btn-primary');
        self.state = { field: null, distinctValues: null };
        self.panel = document.createElement('div');
        self.panel.className = 'edatos-filter-panel';
        self.panel.hidden = true;
        self.container.appendChild(self.panel);

        self.toggleButton.addEventListener('click', function (evt) {
          evt.preventDefault();
          evt.stopPropagation();
          if (self.panel.hidden) {
            self.openFieldList();
          } else {
            self.closePanel();
          }
        });
      },

      activeValues: function (field) {
        return (window.ckan.views.filters.get(field) || []).slice();
      },

      hasActiveFilter: function (field) {
        return this.activeValues(field).length > 0;
      },

      /* Marcar/desmarcar una casilla de VALOR aplica el filtro al instante
         (mismo comportamiento -- y mismo motivo -- que la versión anterior):
         "ckan.views.filters.set()/.unset()" navegan de inmediato en cuanto
         detectan un cambio real. Aquí esa navegación es la del propio
         documento del iframe (no la del padre), así que solo se recarga la
         tabla, igual que ya hace el botón nativo de alternar vista. */
      toggleValue: function (field, value) {
        var current = this.activeValues(field);
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
      },

      openFieldList: function () {
        this.state.field = null;
        this.panel.hidden = false;
        this.container.classList.add('edatos-filter-open');
        this.renderFieldList();
        this.bindCloseOnOutsideInteraction();
      },

      openValueList: function (field) {
        this.state.field = field;
        this.state.distinctValues = null;
        this.renderValueList();
        this.fetchDistinctValues(field);
      },

      closePanel: function () {
        this.panel.hidden = true;
        this.container.classList.remove('edatos-filter-open');
        this.state.field = null;
        this.unbindCloseOnOutsideInteraction();
      },

      renderFieldList: function () {
        var self = this;
        self.panel.innerHTML = '';
        var list = document.createElement('ul');
        list.className = 'edatos-filter-panel-list';
        self.options.fields.forEach(function (field) {
          var li = document.createElement('li');
          li.className = 'edatos-filter-panel-item' +
            (self.hasActiveFilter(field) ? ' edatos-filter-panel-item--checked' : '');
          li.textContent = field;
          /* "stopPropagation()" imprescindible: "openValueList" reconstruye
             el panel de forma SÍNCRONA ("panel.innerHTML = ''") dentro de
             este mismo handler, desconectando este "li" del árbol antes de
             que el clic termine de burbujear -- sin esto, el listener de
             "clic fuera" (en "document") trataría el clic como "fuera del
             panel" y lo cerraría de inmediato. */
          li.addEventListener('click', function (evt) {
            evt.stopPropagation();
            self.openValueList(field);
          });
          list.appendChild(li);
        });
        self.panel.appendChild(list);
        self.panel.appendChild(buildClearRow(function () {
          var current = window.ckan.views.filters.get();
          Object.keys(current).forEach(function (f) {
            window.ckan.views.filters.unset(f);
          });
        }));
      },

      renderValueList: function () {
        var self = this;
        self.panel.innerHTML = '';
        var back = document.createElement('div');
        back.className = 'edatos-filter-panel-back';
        back.textContent = self.state.field;
        back.addEventListener('click', function (evt) {
          evt.stopPropagation();
          self.openFieldList();
        });
        self.panel.appendChild(back);

        var list = document.createElement('ul');
        list.className = 'edatos-filter-panel-list';
        self.panel.appendChild(list);
        self.renderValueItems(list);

        self.panel.appendChild(buildClearRow(function () {
          window.ckan.views.filters.unset(self.state.field);
        }));
      },

      renderValueItems: function (list) {
        var self = this;
        list.innerHTML = '';
        if (self.state.distinctValues === null) {
          var loading = document.createElement('li');
          loading.className = 'edatos-filter-panel-loading';
          loading.textContent = 'Cargando...';
          list.appendChild(loading);
          return;
        }
        if (self.state.distinctValues.length === 0) {
          var empty = document.createElement('li');
          empty.className = 'edatos-filter-panel-empty';
          empty.textContent = 'Sin valores';
          list.appendChild(empty);
          return;
        }
        var checkedValues = self.activeValues(self.state.field);
        self.state.distinctValues.forEach(function (value) {
          var li = document.createElement('li');
          li.className = 'edatos-filter-panel-item' +
            (checkedValues.indexOf(value) !== -1 ? ' edatos-filter-panel-item--checked' : '');
          li.textContent = value;
          li.addEventListener('click', function (evt) {
            evt.stopPropagation();
            self.toggleValue(self.state.field, value);
          });
          list.appendChild(li);
        });
      },

      fetchDistinctValues: function (field) {
        var self = this;
        var url = window.ckan.url('/api/3/action/datastore_search');
        $.getJSON(url, {
          resource_id: self.options.resourceId,
          fields: field,
          distinct: true,
          limit: 100,
          sort: field,
          include_total: false
        }).done(function (data) {
          if (self.state.field !== field) {
            return;
          }
          self.state.distinctValues = (data.result.records || []).map(function (record) {
            return record[field];
          });
          var list = self.panel.querySelector('.edatos-filter-panel-list');
          if (list) {
            self.renderValueItems(list);
          }
        }).fail(function () {
          if (self.state.field !== field) {
            return;
          }
          self.state.distinctValues = [];
          var list = self.panel.querySelector('.edatos-filter-panel-list');
          if (list) {
            self.renderValueItems(list);
          }
        });
      },

      bindCloseOnOutsideInteraction: function () {
        var self = this;
        self._outsideClickHandler = function (evt) {
          if (!self.panel.hidden && !self.container.contains(evt.target)) {
            self.closePanel();
          }
        };
        self._escapeHandler = function (evt) {
          if (evt.key === 'Escape' && !self.panel.hidden) {
            self.closePanel();
          }
        };
        document.addEventListener('click', self._outsideClickHandler);
        document.addEventListener('keydown', self._escapeHandler);
      },

      unbindCloseOnOutsideInteraction: function () {
        if (this._outsideClickHandler) {
          document.removeEventListener('click', this._outsideClickHandler);
          this._outsideClickHandler = null;
        }
        if (this._escapeHandler) {
          document.removeEventListener('keydown', this._escapeHandler);
          this._escapeHandler = null;
        }
      }
    };
  });
  });
})();
