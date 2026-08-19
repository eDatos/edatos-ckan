/*
 * Loads the external eDatos header and footer (complementos-apps) from the
 * browser.
 *
 * CKAN used to download the header while rendering every page, which meant one
 * request to complementos-apps and two to the common metadata service per page
 * view. Crawlers sweeping the catalogue turned that into hundreds of thousands
 * of daily requests, so the fetch moved here: bots do not run JavaScript.
 *
 * The footer was not fetched per render but downloaded once at startup and
 * written over templates/footer.html, which is why the deployment needed that
 * file to be world writable. It is fetched here too so that nothing is written
 * to disk any more.
 *
 * Both URLs are built server side (see `get_header_url` and `get_footer_url` in
 * plugin/__init__.py) and handed over in the container's data-edatos-html-url,
 * so no metadata property has to be resolved from the browser either.
 */
(function () {
    'use strict';

    var CONTAINER_SELECTOR = '[data-edatos-html-url]';

    function ready(callback) {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', callback);
        } else {
            callback();
        }
    }

    /*
     * innerHTML inserts <script> nodes without executing them, so each one has
     * to be replaced by a fresh copy. The header ships around a dozen of them
     * (language selector, user menu, logout modal), so it does not work at all
     * without this. async = false preserves their original execution order.
     */
    function reinsertScripts(element) {
        Array.prototype.slice
            .call(element.getElementsByTagName('script'))
            .forEach(function (script) {
                var copy = document.createElement('script');
                Array.prototype.forEach.call(script.attributes, function (attribute) {
                    copy.setAttribute(attribute.name, attribute.value);
                });
                copy.text = script.text;
                copy.async = false;
                script.parentNode.replaceChild(copy, script);
            });
    }

    function load(container) {
        var url = container.dataset.edatosHtmlUrl;

        // credentials are omitted to keep parity with the old server-side
        // fetch, which sent no cookies either.
        fetch(url, { credentials: 'omit' })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error(url + ': HTTP ' + response.status);
                }
                return response.text();
            })
            .then(function (html) {
                container.innerHTML = html;
                reinsertScripts(container);
            })
            .catch(function (error) {
                console.error('eDatos ' + container.id + ' not loaded', error);
            });
    }

    ready(function () {
        Array.prototype.forEach.call(
            document.querySelectorAll(CONTAINER_SELECTOR), load);
    });
})();
