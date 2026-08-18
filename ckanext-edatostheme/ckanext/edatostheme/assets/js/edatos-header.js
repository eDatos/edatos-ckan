/*
 * Loads the external eDatos header (complementos-apps) from the browser.
 *
 * CKAN used to download it while rendering every page, which meant one request
 * to complementos-apps and two to the common metadata service per page view.
 * Crawlers sweeping the catalogue turned that into hundreds of thousands of
 * daily requests, so the fetch moved here: bots do not run JavaScript.
 *
 * The URL is built server side (see `get_header_url` in plugin/__init__.py) and
 * handed over in the container's data-header-url, so no metadata property has
 * to be resolved from the browser either.
 */
(function () {
    'use strict';

    var HEADER_ID = 'edatos-header';

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

    ready(function () {
        var header = document.getElementById(HEADER_ID);
        if (!header || !header.dataset.headerUrl) {
            return;
        }

        // credentials are omitted to keep parity with the old server-side
        // fetch, which sent no cookies either.
        fetch(header.dataset.headerUrl, { credentials: 'omit' })
            .then(function (response) {
                if (!response.ok) {
                    throw new Error(header.dataset.headerUrl +
                        ': HTTP ' + response.status);
                }
                return response.text();
            })
            .then(function (html) {
                header.innerHTML = html;
                reinsertScripts(header);
            })
            .catch(function (error) {
                console.error('eDatos header not loaded', error);
            });
    });
})();
