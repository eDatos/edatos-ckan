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
      /* Reengancha el clic de "Agregar Filtro" para el documento de iframe
         ACTUAL -- ver el comentario grande de "bindFilterToggleClick" (más
         abajo en este fichero) sobre por qué hace falta repetir esto en
         cada recarga interna, no solo la primera vez. Sólo si el panel ya
         se montó con éxito (comprobar "__edatosOpenPanel", colgado al
         final de "setupCustomFilterPanel") -- en la primera llamada de
         "moveButtonsIntoDtButtons" tras cargar la página, "setupCustomFilterPanel"
         puede no haber tenido éxito todavía (reintenta por su cuenta, ver
         "filterPanelPoll" en el "DOMContentLoaded" de más abajo). */
      if (filtersContainer.__edatosOpenPanel) {
        bindFilterToggleClick(filtersContainer);
      }
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
     CKAN core "resource-view-filters" (fuera de este repo) con select2. La
     versión realmente vendored en este proyecto es 3.5.x (confirmado
     inspeccionando el bundle servido: usa el patrón interno "AbstractSelect2"/
     "prepareOpts", propio de 3.5.x -- el comentario original de este fichero
     decía "v4, adaptador AttachBody", pero esa clase y la opción
     "dropdownParent" son de select2 v4 y no existen en este bundle). select2
     3.5.x siempre ancla el panel flotante de opciones a "$('body')" -- y ese
     "$" es el jQuery del documento PADRE, porque el propio plugin select2 se
     cargó y ejecutó una única vez ahí (su IIFE cierra sobre esa instancia de
     jQuery para siempre, sin importar en qué documento viva el control sobre
     el que se invoque después). Al mover el control al <iframe>, select2
     calcula la posición del panel con "jQuery.offset()" del propio control
     (coordenadas relativas al documento del iframe, incluyendo su scroll
     interno) pero inserta el panel en el <body> del documento PADRE --
     coordenadas de documentos distintos combinadas sin conversión, así que el
     panel aparece desconectado del control (verificado en el navegador:
     aparecía en la esquina superior izquierda de la página en vez de bajo el
     desplegable "Seleccione un campo").

     Fix real, en dos partes:
     1) "patchSelect2ForIframes" ya NO intenta fijar "dropdownParent" (opción
        inexistente en 3.5.x, no-op inofensivo) -- solo necesitaba dejar de
        romper el arranque de select2 (ver nota de "defaults" más abajo).
     2) "fixDropdownPositionOnOpen" corrige a mano, en cada apertura, la
        posición del panel ya insertado por select2 en el <body> del
        documento padre: a las coordenadas (erróneas, relativas solo al
        iframe) que select2 ya calculó se les suma el offset real del propio
        <iframe> dentro del documento padre (su "getBoundingClientRect()" +
        scroll de la página padre), y se les resta el scroll interno del
        iframe (normalmente 0, la vista de tabla no hace scroll propio, pero
        se calcula por robustez). Deliberadamente NO se mueve el nodo del
        panel al documento del iframe con "adoptNode": select2 vuelve a
        reposicionarlo (con las coordenadas erróneas de siempre) en sus
        propios listeners de scroll/resize, así que corregir solo la
        posición en la apertura (y en cada scroll mientras esté abierto) es
        más robusto que pelear por la propiedad del nodo.
     Límite conocido (igual que antes): si la URL ya trae filtros activos
     ("?filters=..."), sus desplegables de valor se inicializan durante el
     arranque del módulo de CKAN core, antes de que este script mueva
     ".resource-view-filters" al iframe -- en ese caso "el ownerDocument" del
     control en ese momento es el documento padre, así que ni el parche ni la
     corrección de posición entran en juego para ese desplegable en concreto
     (si el usuario lo abre igualmente, se comporta como sin este fix, pero
     ya en su documento correcto). Los filtros añadidos después de la carga
     (el caso normal, incluido el primer clic en "Agregar Filtro") sí quedan
     cubiertos. */
  function fixDropdownPositionOnOpen(inputEl) {
    var iframeDoc = inputEl.ownerDocument;
    if (!iframeDoc.defaultView) {
      return;
    }
    var iframeEl = Array.prototype.filter.call(
      document.querySelectorAll('iframe'),
      function (f) {
        try {
          return f.contentDocument === iframeDoc;
        } catch (err) {
          return false;
        }
      }
    )[0];
    if (!iframeEl) {
      return;
    }

    /* Deliberadamente NO se parte de "drop.style.top/left" (lo que select2
       ya haya escrito ahí) para sumarle el offset del iframe: el desplegable
       de VALOR de un filtro consulta "datastore_search" por AJAX y select2
       vuelve a invocar su propio cálculo de posición (con las coordenadas de
       siempre, sólo relativas al iframe) cuando llegan los resultados --
       después de que la primera llamada a "reposition()" ya haya corregido la
       posición. Si "reposition()" tomara el valor ya
       corregido como base y le sumara el offset otra vez, el panel se iría
       cada vez más lejos en cada re-cálculo (no idempotente). Por eso aquí
       se recalcula siempre desde cero a partir de la geometría real
       ("getBoundingClientRect()" del propio control + del <iframe>), nunca a
       partir del estilo que select2 dejó puesto -- así da igual cuántas
       veces (open inicial, respuesta AJAX, scroll, resize) se llame: el
       resultado es siempre el mismo valor absoluto correcto. */
    function reposition() {
      var drop = document.querySelector('.select2-drop-active');
      if (!drop) {
        return;
      }
      var iframeRect = iframeEl.getBoundingClientRect();
      var inputRect = inputEl.getBoundingClientRect();
      drop.style.top = (iframeRect.top + inputRect.bottom + window.pageYOffset) + 'px';
      drop.style.left = (iframeRect.left + inputRect.left + window.pageXOffset) + 'px';
    }

    reposition();
    /* select2 puede recalcular su propia posición (equivocada) de forma
       asíncrona -- de inmediato en un microtask/tick propio, y de nuevo
       cuando llegan los resultados del AJAX de "datastore_search" -- así que
       se reintenta durante una ventana breve tras la apertura, además de
       mientras el panel siga abierto y la página haga scroll o resize. */
    var attempts = 0;
    var poll = setInterval(function () {
      attempts += 1;
      if (!document.querySelector('.select2-drop-active')) {
        clearInterval(poll);
        return;
      }
      reposition();
      if (attempts >= 20) {
        clearInterval(poll);
      }
    }, 100);

    function onScrollOrResize() {
      if (document.querySelector('.select2-drop-active')) {
        reposition();
      }
    }
    window.addEventListener('scroll', onScrollOrResize, true);
    window.addEventListener('resize', onScrollOrResize);
  }

  function patchSelect2ForIframes(jq) {
    if (!jq || !jq.fn || !jq.fn.select2 || jq.fn.select2.__edatosIframeAware) {
      return;
    }
    var original = jq.fn.select2;
    function patched(options) {
      var el = this[0];
      /* OJO: no filtrar aquí por "el.ownerDocument !== document" antes de
         decidir si engancha el listener de reposicionamiento. El desplegable
         de VALOR de un filtro (".resource-view-filter-values", construido en
         "_buildDropdown" del módulo de core) llama a ".select2()" ANTES de
         insertar el <input> en el árbol vivo del iframe (el "template" con el
         select2 ya inicializado se añade al DOM -- y por tanto se adopta al
         documento del iframe -- recién en el "dropdowns.append(...)" del
         llamante). En ese momento "el.ownerDocument" todavía es el documento
         padre, así que esta comprobación fallaría y el filtro de VALOR se
         quedaría sin el fix (verificado: reproducía el mismo desplegable en
         la esquina superior izquierda, solo que para el segundo select, no
         el primero). Por eso el chequeo de documento se hace dentro de
         "fixDropdownPositionOnOpen", en el momento de la apertura -- para
         entonces el nodo ya se adoptó al documento que le corresponda. */
      if (el && options !== null && typeof options === 'object') {
        var result = original.call(this, options);
        this.on('select2-open', function () {
          fixDropdownPositionOnOpen(el);
        });
        return result;
      }
      return original.apply(this, arguments);
    }
    /* select2 3.5.x expone sus estáticos (`defaults`, `locales`, etc.)
       colgando de la propia referencia "$.fn.select2" y los lee así
       internamente -- p.ej. "prepareOpts" hace literalmente
       "$.fn.select2.defaults.debug", no una variable local cerrada sobre
       "original". Si no se copian esos estáticos a "patched" antes de
       sustituir "jq.fn.select2", esa lectura interna revienta con "Cannot
       read properties of undefined (reading 'debug')" en la siguiente
       llamada a ".select2(...)" -- incluida la que dispara el propio parche
       -- porque "$.fn.select2" ya apunta a "patched", cuyo ".defaults" es
       undefined. Verificado: esto es justo lo que rompía "Agregar Filtro" en
       el recurso (el desplegable de campos nunca llegaba a inicializarse,
       así que no se veían opciones al pulsar el botón). */
    jq.extend(patched, original);
    patched.__edatosIframeAware = true;
    jq.fn.select2 = patched;
  }

  /* Sustituye el flujo por defecto del botón "Agregar Filtro" (select2 campo
     -> select2 valor, un valor cada vez -- ver bloque de comentarios sobre
     "patchSelect2ForIframes"/"fixDropdownPositionOnOpen" más arriba) por un
     panel de checkboxes fusionado visualmente con el propio botón, fiel al
     mockup de Figma (nodo 12941:9342 "BotonDesplegableM" + panel de
     "Opción 1..5" / "Eliminar filtro"), en vez de replicar el checklist
     estático de Figma tal cual (esa lista de "Opción X" es un placeholder
     genérico del componente reutilizable "BotonDesplegableM" -- el campo a
     filtrar y sus valores son dinámicos, vienen de la tabla real).
     Marcar/desmarcar una casilla de VALOR aplica el filtro al instante
     (recarga la página con la nueva "?filters=" en cada clic, a petición
     expresa -- ver "toggleValue" más abajo); sigue permitiendo acabar con
     varios valores del mismo campo activos a la vez, solo que cada uno se
     aplica en su propio recargado en vez de acumularse sin recargar.

     Arquitectura: el botón real ("a.btn-primary", generado por CKAN core en
     "_buildAddFilterButton") se queda en el DOM -- solo se le intercepta el
     click en fase de CAPTURA sobre ".resource-view-filters" (su ancestro),
     no sobre el propio botón. Esto es necesario porque un listener en fase
     de captura registrado sobre el MISMO elemento que ya tiene un listener
     en fase de burbuja (el de CKAN core, registrado antes, vía jQuery
     ".click()") NO se garantiza que se ejecute antes: para listeners en el
     propio nodo objetivo, el orden es el de registro, no el de la bandera
     "capture" -- esa bandera solo importa para listeners en ANCESTROS,
     donde la fase de captura (de la raíz hacia el objetivo) siempre ocurre
     antes de que el evento llegue al objetivo. Verificado: intentar
     interceptar en el propio botón dejaba pasar igualmente el handler de
     CKAN core (seguía creando su select2). Enganchando el listener en
     ".resource-view-filters" con capture:true y llamando a
     "stopPropagation()" ahí, el evento nunca llega a burbujear hasta el
     botón, así que el handler de core nunca se dispara.

     El estado real de los filtros (qué campos/valores están activos) sigue
     viviendo en "ckan.views.filters" (CKAN core, view-filters.js) -- este
     panel solo construye su propia UI encima de esa misma API pública
     ("get"/"set"/"unset"), así que la URL resultante y el recargado de la
     tabla son IDÉNTICOS a los que ya producía el flujo por defecto (mismo
     mecanismo, otra interfaz). */
  /* Engancha (o reengancha) el clic de "Agregar Filtro" sobre el
     "filtersContainer" ACTUAL -- se llama una vez al montar el panel
     (dentro de "setupCustomFilterPanel") y de nuevo cada vez que
     "moveButtonsIntoDtButtons" re-adopta "filtersContainer" en un
     documento de iframe nuevo (cada recarga interna que dispara el botón
     de alternar tabla/lista).

     Motivo: un único listener capturado una sola vez al arrancar dejaba
     de reaccionar a clics reales tras uno o más ciclos de "adoptNode"
     entre documentos de iframe sucesivos -- verificado en el navegador con
     un listener de diagnóstico ADICIONAL sobre el mismo nodo: ese listener
     nuevo SÍ veía el clic (con el "target" correcto, el único
     "a.btn-primary" que existe en todo el documento), pero
     "evt.defaultPrevented" seguía en "false" después, es decir, el
     listener original de verdad no estaba actuando -- ni siquiera
     comparando "evt.target" contra una consulta fresca de
     "filtersContainer.querySelector('a.btn-primary')" en el momento del
     clic (intento previo, insuficiente). No se aisló la causa exacta de
     por qué un listener "viejo" deja de reaccionar mientras uno "nuevo"
     sobre el mismo nodo sí lo hace, pero desengachar y reenganchar un
     listener fresco en cada re-adopción es la vía robusta que sí funciona
     de forma repetible, sin depender de entender ese mecanismo interno.
     Guardar la función en "filtersContainer.__edatosClickHandler" permite
     desengancharla la próxima vez sin acumular listeners duplicados en
     cada toggle (que competirían entre sí abriendo/cerrando el panel a la
     vez en un mismo clic). */
  function bindFilterToggleClick(filtersContainer) {
    if (filtersContainer.__edatosClickHandler) {
      filtersContainer.removeEventListener('click', filtersContainer.__edatosClickHandler, true);
    }
    var handler = function (evt) {
      var currentToggleButton = filtersContainer.querySelector('a.btn-primary');
      if (!currentToggleButton ||
          (currentToggleButton !== evt.target && !currentToggleButton.contains(evt.target))) {
        return;
      }
      evt.preventDefault();
      evt.stopPropagation();
      var panel = filtersContainer.__edatosPanelEl;
      if (panel.hidden) {
        filtersContainer.__edatosOpenPanel();
      } else {
        filtersContainer.__edatosClosePanel();
      }
    };
    filtersContainer.__edatosClickHandler = handler;
    filtersContainer.addEventListener('click', handler, true);
  }

  /* Devuelve "true" si el panel quedó montado, "false" si aún no había
     nada que enganchar (el llamante reintenta -- ver más abajo por qué
     hace falta reintentar en vez de bastar con "DOMContentLoaded"). */
  function setupCustomFilterPanel(filtersContainer) {
    var jq = window.jQuery;
    if (!jq || !window.ckan || !window.ckan.views || !window.ckan.views.filters) {
      return false;
    }
    /* El botón "Agregar Filtro" (y el resto de ".resource-view-filters") lo
       construye en tiempo de ejecución el módulo de CKAN core
       "resource-view-filters" (su "initialize()", fuera de este repo) al
       arrancar como "ckan.module" -- no existe ninguna plantilla Jinja que
       lo renderice de entrada. Ese arranque de módulos de CKAN core ocurre
       en su propio momento (tras cargar jQuery y el propio "ckan.js"), que
       no tiene por qué haber pasado ya cuando se dispara ESTE
       "DOMContentLoaded": este bundle ("edatostheme_js") se carga ANTES que
       "jquery.js" en el <head> (ver nota más abajo, en el registro del
       listener), así que nuestro listener de "DOMContentLoaded" queda
       registrado -- y por tanto se ejecuta -- ANTES que el que arranca los
       módulos de CKAN core (para listeners sobre el MISMO evento y target,
       el orden de ejecución es el de registro). Verificado en consola: la
       primera vez que se llama a esta función, ".resource-view-filters"
       existe pero está vacío salvo el "<div>" que "initialize()" aún no ha
       rellenado -- "a.btn-primary" todavía no existe. Por eso el llamante
       reintenta con un "setInterval" corto, el mismo patrón que ya usa
       "tryMove" más abajo para esperar a que ".dt-buttons" esté listo. */
    var toggleButton = filtersContainer.querySelector('a.btn-primary');
    if (!toggleButton) {
      return false;
    }

    /* El "filtersDiv" que CKAN core añade ANTES del botón (ver
       "initialize()" en resource-view-filters.js) solo tiene contenido si
       la URL ya traía "?filters=..." al cargar la página -- renderiza esos
       filtros preexistentes con su select2 por defecto, de forma
       independiente al botón. Se oculta para no mezclar dos estilos/flujos
       distintos a la vez; el propio panel nuevo (más abajo) ya sabe leer
       ese mismo estado vía "ckan.views.filters.get()" y permite editarlo
       igual. */
    var legacyFiltersDiv = filtersContainer.firstElementChild;
    if (legacyFiltersDiv && legacyFiltersDiv !== toggleButton) {
      legacyFiltersDiv.style.display = 'none';
    }

    var resourceId = filtersContainer.getAttribute('data-module-resource-id');
    var fields;
    try {
      fields = JSON.parse(filtersContainer.getAttribute('data-module-fields') || '[]');
    } catch (err) {
      fields = [];
    }

    /* Se lee "filtersContainer.ownerDocument" en cada llamada (nunca se
       captura en una variable una sola vez) por el mismo motivo que
       "bindCloseOnOutsideInteraction" más abajo: ".resource-view-filters"
       empieza en el documento padre pero se traslada al <iframe> con
       "adoptNode" poco después de cargar la página, y las pantallas del
       panel se (re)construyen cada vez que el usuario interactúa -- casi
       siempre después de que ese traslado ya haya ocurrido. */
    function currentDoc() {
      return filtersContainer.ownerDocument;
    }
    var panel = currentDoc().createElement('div');
    panel.className = 'edatos-filter-panel';
    panel.hidden = true;
    filtersContainer.appendChild(panel);

    var state = { field: null, distinctValues: null };

    function activeValues(field) {
      return (window.ckan.views.filters.get(field) || []).slice();
    }

    function hasActiveFilter(field) {
      return activeValues(field).length > 0;
    }

    /* A petición expresa: marcar/desmarcar una casilla de VALOR aplica el
       filtro al instante, en vez de acumular varios cambios en memoria y
       aplicarlos solo al cerrar el panel (que era el comportamiento de la
       versión anterior de este mismo panel). "ckan.views.filters.set()/
       .unset()" navegan de inmediato ("window.location.href = ...") en
       cuanto detectan un cambio real -- cada clic sobre una casilla de
       valor recarga la página entera con la nueva "?filters=". Sigue
       permitiendo marcar varios valores del mismo campo (cada uno en su
       propio recargado, no en una única sesión sin recargar). */
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

    /* Escuchas de "cerrar al hacer clic fuera"/Escape, enganchadas y
       desenganchadas dinámicamente en cada apertura -- ver más abajo por
       qué no pueden engancharse una única vez en "setup". */
    var outsideClickHandler = null;
    var escapeHandler = null;

    function bindCloseOnOutsideInteraction() {
      /* "filtersContainer.ownerDocument" se lee aquí, en el momento de
         ABRIR el panel, no una vez en "setup()": ".resource-view-filters"
         (con el panel ya colgado de él) arranca en el documento PADRE, pero
         "resource-view-toolbar.js" lo traslada con "adoptNode" al <iframe>
         poco después de cargar la página (ver "moveButtonsIntoDtButtons").
         Si esta función capturase "doc" una sola vez al arrancar (como
         hacía una versión anterior de este parche), el listener de "clic
         fuera" se quedaría enganchado al documento padre para siempre --
         tras el traslado, los clics dentro del iframe ya no burbujean hasta
         ese documento (cada iframe tiene su propio árbol de eventos), así
         que el panel dejaría de poder cerrarse solo con un clic fuera
         (aunque el propio botón, con su listener en "filtersContainer",
         seguiría abriendo/cerrando bien, porque ese nodo SÍ viaja con la
         adopción). Al enganchar en cada apertura (que normalmente ocurre
         bastante después de que el traslado ya haya terminado), se lee
         siempre el documento correcto. */
      var liveDoc = filtersContainer.ownerDocument;
      outsideClickHandler = function (evt) {
        if (!panel.hidden && !filtersContainer.contains(evt.target)) {
          closePanel();
        }
      };
      escapeHandler = function (evt) {
        if (evt.key === 'Escape' && !panel.hidden) {
          closePanel();
        }
      };
      liveDoc.addEventListener('click', outsideClickHandler);
      liveDoc.addEventListener('keydown', escapeHandler);
    }

    function unbindCloseOnOutsideInteraction() {
      var liveDoc = filtersContainer.ownerDocument;
      if (outsideClickHandler) {
        liveDoc.removeEventListener('click', outsideClickHandler);
        outsideClickHandler = null;
      }
      if (escapeHandler) {
        liveDoc.removeEventListener('keydown', escapeHandler);
        escapeHandler = null;
      }
    }

    function closePanel() {
      panel.hidden = true;
      filtersContainer.classList.remove('edatos-filter-open');
      state.field = null;
      unbindCloseOnOutsideInteraction();
    }

    function openFieldList() {
      state.field = null;
      panel.hidden = false;
      filtersContainer.classList.add('edatos-filter-open');
      renderFieldList();
      bindCloseOnOutsideInteraction();
    }

    function openValueList(field) {
      state.field = field;
      state.distinctValues = null;
      renderValueList();
      fetchDistinctValues(field);
    }

    function renderFieldList() {
      panel.innerHTML = '';
      var list = currentDoc().createElement('ul');
      list.className = 'edatos-filter-panel-list';
      fields.forEach(function (field) {
        var li = currentDoc().createElement('li');
        li.className = 'edatos-filter-panel-item' +
          (hasActiveFilter(field) ? ' edatos-filter-panel-item--checked' : '');
        li.textContent = field;
        /* "stopPropagation()" es imprescindible aquí, no un extra de
           limpieza: "openValueList" llama a "renderValueList()", que hace
           "panel.innerHTML = ''" de forma SÍNCRONA dentro de este mismo
           handler -- eso desconecta el propio "li" que se acaba de pulsar
           del árbol del documento ANTES de que el evento termine de
           burbujear. Si se dejara burbujear hasta el listener de "clic
           fuera" (más abajo, en "document"), "filtersContainer.contains
           (evt.target)" daría "false" para un nodo ya desconectado --
           tratando este clic como "fuera del panel" y cerrándolo de
           inmediato, deshaciendo la propia apertura que acaba de disparar.
           Verificado: sin este "stopPropagation()", pulsar un campo abría y
           cerraba la pantalla de valores en el mismo clic. */
        li.addEventListener('click', function (evt) {
          evt.stopPropagation();
          openValueList(field);
        });
        list.appendChild(li);
      });
      panel.appendChild(list);
      panel.appendChild(buildClearRow(function () {
        /* En la pantalla de campos (sin uno concreto seleccionado),
           "Eliminar filtro" limpia TODOS los filtros activos -- lectura
           razonable del mismo texto que en la pantalla de valores (donde
           limpia solo el campo actual), dado que Figma solo contempla una
           fila "Eliminar filtro" por panel, no una por campo. */
        var current = window.ckan.views.filters.get();
        Object.keys(current).forEach(function (f) {
          window.ckan.views.filters.unset(f);
        });
      }));
    }

    function renderValueList() {
      panel.innerHTML = '';
      var back = currentDoc().createElement('div');
      back.className = 'edatos-filter-panel-back';
      back.textContent = state.field;
      /* "stopPropagation()" necesario por el mismo motivo que en el listado
         de campos: "openFieldList()" desconecta este "back" (y todo el
         resto del panel de valores) del árbol de forma síncrona, antes de
         que el clic termine de burbujear hasta el listener de "clic fuera"
         en "document". */
      back.addEventListener('click', function (evt) {
        evt.stopPropagation();
        openFieldList();
      });
      panel.appendChild(back);

      var list = currentDoc().createElement('ul');
      list.className = 'edatos-filter-panel-list';
      panel.appendChild(list);
      renderValueItems(list);

      panel.appendChild(buildClearRow(function () {
        window.ckan.views.filters.unset(state.field);
      }));
    }

    function buildClearRow(onClear) {
      var clear = currentDoc().createElement('div');
      clear.className = 'edatos-filter-panel-clear';
      clear.textContent = 'Eliminar filtro';
      clear.addEventListener('click', function (evt) {
        evt.stopPropagation();
        onClear();
        closePanel();
      });
      return clear;
    }

    function renderValueItems(list) {
      list.innerHTML = '';
      if (state.distinctValues === null) {
        var loading = currentDoc().createElement('li');
        loading.className = 'edatos-filter-panel-loading';
        loading.textContent = 'Cargando...';
        list.appendChild(loading);
        return;
      }
      if (state.distinctValues.length === 0) {
        var empty = currentDoc().createElement('li');
        empty.className = 'edatos-filter-panel-empty';
        empty.textContent = 'Sin valores';
        list.appendChild(empty);
        return;
      }
      var checkedValues = activeValues(state.field);
      state.distinctValues.forEach(function (value) {
        var li = currentDoc().createElement('li');
        li.className = 'edatos-filter-panel-item' +
          (checkedValues.indexOf(value) !== -1 ? ' edatos-filter-panel-item--checked' : '');
        li.textContent = value;
        /* "stopPropagation()" necesario por el mismo motivo que en el
           listado de campos: "toggleValue" dispara "ckan.views.filters.set()
           /.unset()", que navega de inmediato -- pero antes de que el
           navegador complete esa navegación, el script síncrono sigue
           corriendo, así que este "li" (o el panel entero) podría acabar
           desconectándose de un renderizado posterior antes de que el clic
           termine de burbujear. */
        li.addEventListener('click', function (evt) {
          evt.stopPropagation();
          toggleValue(state.field, value);
          renderValueItems(list);
        });
        list.appendChild(li);
      });
    }

    function fetchDistinctValues(field) {
      var url = window.ckan.url('/api/3/action/datastore_search');
      jq.getJSON(url, {
        resource_id: resourceId,
        fields: field,
        distinct: true,
        limit: 100,
        sort: field,
        include_total: false
      }).done(function (data) {
        /* El usuario pudo volver a la lista de campos o abrir OTRO campo
           antes de que llegara esta respuesta; si ya no es el campo activo,
           se descarta para no pintar valores del campo equivocado. */
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

    /* "openFieldList"/"closePanel"/"panel" se cuelgan del propio nodo
       "filtersContainer" (no solo se cierran sobre el "click" de más abajo)
       para que "bindFilterToggleClick" -- llamada de nuevo en cada
       recarga interna del iframe, ver "moveButtonsIntoDtButtons" -- pueda
       reenganchar el clic sin tener que reconstruir el panel/estado cada
       vez. Un nodo conserva las propiedades que se le cuelguen aunque se
       traslade de documento con "adoptNode" (a diferencia de los listeners
       de un "removeEventListener" que sí hay que rehacer, ver más abajo). */
    filtersContainer.__edatosOpenPanel = openFieldList;
    filtersContainer.__edatosClosePanel = closePanel;
    filtersContainer.__edatosPanelEl = panel;
    bindFilterToggleClick(filtersContainer);

    return true;
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

    /* "setupCustomFilterPanel" necesita que CKAN core ya haya construido
       "a.btn-primary" dentro de ".resource-view-filters" (su propio
       "ckan.module" "resource-view-filters", fuera de este repo) -- eso NO
       ha ocurrido todavía la primera vez que se llega aquí (ver comentario
       grande dentro de la propia función), así que se reintenta con el
       mismo patrón de "setInterval" que ya usa "tryMove" más abajo para
       ".dt-buttons". */
    if (filtersContainer) {
      var filterPanelReady = setupCustomFilterPanel(filtersContainer);
      if (!filterPanelReady) {
        var filterPanelAttempts = 0;
        var filterPanelPoll = setInterval(function () {
          filterPanelAttempts += 1;
          if (setupCustomFilterPanel(filtersContainer) || filterPanelAttempts >= 20) {
            clearInterval(filterPanelPoll);
          }
        }, 100);
      }
    }

    if (!actions || !iframe) {
      return;
    }

    var buttons = Array.prototype.slice.call(
      actions.querySelectorAll('.resource-view-toolbar-btn')
    );
    if (buttons.length === 0) {
      return;
    }

    /* OJO: el botón "Table/List toggle" (fa-table/fa-list, generado por el
       vendor ckanext-datatablesview -- ver "datatablesview.js", acción del
       botón "viewToggleButton") hace "window.location.reload()" -- pero
       "window" ahí es el del PROPIO <iframe> (esa plantilla vendored,
       "datatables/datatables_view.html", es lo que se sirve dentro del
       <iframe>, no la página padre), así que cada clic en ese botón (y, en
       general, cualquier cambio de "gcurrentView"/"lastView" al cargar la
       página ya en modo "list") recarga SOLO el <iframe> -- la página padre
       (donde vive este script) nunca vuelve a ejecutar su
       "DOMContentLoaded". Confirmado en el navegador: tras un clic, las
       "resource-view-toolbar-btn" ("Pantalla completa"/"Incrustar") YA NO
       están en ".resource-view .actions" del documento padre -- el primer
       "moveButtonsIntoDtButtons" (más abajo) ya las había trasladado ahí con
       "adoptNode" en la carga inicial, así que si esa carga inicial tuvo
       éxito, una versión anterior de este fichero marcaba "moved = true"
       PARA SIEMPRE y nunca volvía a intentarlo -- dejando el nuevo documento
       del iframe (tras cada recarga interna) sin sus botones movidos y sin
       "ensureFontAwesomeProInIframe": efecto visible, los iconos de la barra
       (incluido el propio botón de alternar tabla/lista) se veían como
       cuadros vacíos y "Buscar:"/"Mostrando X registros" quedaban sin mover,
       solapados en su posición original -- en CUALQUIER pulsación del
       botón, no solo al entrar en modo "list".
       Fix: en vez de un flag booleano de un solo uso, se recuerda CUÁL fue
       el último "iframeDoc" ya resuelto con éxito (comparado por
       identidad de objeto, no solo "existe"), y se vuelve a intentar el
       traslado en cada evento "load" del iframe (que sí se dispara de
       nuevo en cada recarga interna, aunque la página padre no recargue).
       "adoptNode" funciona igual de bien aunque el nodo origen ("buttons"/
       "filtersContainer", capturados una única vez al arrancar) ya
       pertenezca a un documento de iframe anterior y descartado -- solo
       cambia su "ownerDocument" y lo desconecta de donde estuviera, sin
       depender de que ese documento antiguo siga vivo -- así que los mismos
       nodos (con sus listeners intactos, como ya garantizaba "adoptNode"
       frente a "cloneNode") se pueden re-adoptar una y otra vez en cada
       nuevo documento del iframe. */
    var lastHandledDoc = null;
    var domObserver = null;

    function getIframeDoc() {
      try {
        return iframe.contentDocument;
      } catch (err) {
        return null;
      }
    }

    /* Devuelve "true" en cuanto "iframeDoc" (el documento ACTUAL del
       iframe, que cambia en cada recarga interna) ya tiene los botones
       movidos -- ya fuera en esta misma llamada o en una anterior para ese
       mismo documento. */
    function tryMove(iframeDoc) {
      if (!iframeDoc) {
        return false;
      }
      if (iframeDoc === lastHandledDoc) {
        return true;
      }
      if (moveButtonsIntoDtButtons(iframeDoc, buttons, filtersContainer)) {
        lastHandledDoc = iframeDoc;
        if (domObserver) {
          domObserver.disconnect();
          domObserver = null;
        }
        return true;
      }
      return false;
    }

    /* ".dt-buttons.btn-group" lo crea en tiempo de ejecución la extensión
       vendored ckanext-datatablesview (fuera de este repo) al inicializar
       DataTables -- y ese init puede tardar (sobre todo en modo "list"/
       responsive, donde el vendor llega a lanzar una excepción interna sin
       capturar durante el ajuste de columnas, "Cannot read properties of
       undefined (reading 'style')" en su "_fnScrollDraw" -- confirmado en
       la consola del navegador), así que no basta con comprobarlo una sola
       vez en el "load" del iframe. Se engancha un MutationObserver sobre su
       "<body>" que reacciona en cuanto ".dt-buttons" aparezca en ESE
       documento concreto, sin depender de un número de reintentos fijo. */
    function tryAttachObserver(iframeDoc) {
      if (!iframeDoc || iframeDoc === lastHandledDoc || !iframeDoc.body) {
        return;
      }
      if (domObserver) {
        domObserver.disconnect();
      }
      domObserver = new MutationObserver(function () {
        tryMove(getIframeDoc());
      });
      domObserver.observe(iframeDoc.body, { childList: true, subtree: true });
    }

    /* El "load" del iframe se dispara en CADA recarga (la inicial y cada
       recarga interna disparada por el botón de alternar tabla/lista), así
       que es el punto de entrada principal -- no solo un caso especial. */
    iframe.addEventListener('load', function () {
      var iframeDoc = getIframeDoc();
      if (tryMove(iframeDoc)) {
        return;
      }
      tryAttachObserver(iframeDoc);
    });

    /* Poll de respaldo (por si "load" ya disparó antes de registrar este
       listener, o el documento tardara en tener "<body>" para el
       observer) -- sin límite de intentos ni de tiempo: a diferencia de la
       versión anterior, esto debe seguir funcionando durante toda la vida
       de la página, ya que el usuario puede alternar tabla/lista tantas
       veces como quiera y cada clic dispara una recarga interna nueva que
       hay que volver a atender. */
    setInterval(function () {
      var iframeDoc = getIframeDoc();
      if (tryMove(iframeDoc)) {
        return;
      }
      tryAttachObserver(iframeDoc);
    }, 250);
  });
})();
