window.onload = function () {

    const SITE_URL = "FILL_SITE_URL";
    const I18N_COOKIE = "chosenLocale";

    function getObjectCookie() {
        const separador = '; ';
        let cookies = document.cookie;
        let objCookies = Object.fromEntries(
            cookies
                .split(separador)
                .map(
                    c => c.split('=')
                ));
        return objCookies
    };

    function getLocalLanguage() {
        let cookieObject = getObjectCookie();
        if (cookieObject.hasOwnProperty(I18N_COOKIE)) {
            return cookieObject.chosenLocale;
        }
        return typeof Edatos !== 'undefined' && typeof Edatos.i18n.getDefaultLanguage !== 'undefined' ? Edatos.i18n.getDefaultLanguage() : 'es';
    };

    function breakAddress(url) {
        var data = url.split(SITE_URL);
        var domain = data[0];

        // Comprobar hay path y devolver el resto de la dirección
        data = data[1].split("/");
        var language = data[0];
        if (data[1]) {
            return [domain,language,data.slice(1).join("/")];
        }
        return [domain,language,"home"];
    }

    function redirectChosenLanguage(language = 'es') {
        language = getLocalLanguage();
        const currentUrl = new URL(window.location.href);
        const path = currentUrl.href;

        var urlArray = breakAddress(path);
        var nuevaUrl = '';

        if (urlArray[1] !== language) {
            if (urlArray[2] === "home") {
                nuevaUrl = SITE_URL.concat(language,"/");
            } else {
                nuevaUrl = SITE_URL.concat(language,"/",urlArray[2]);
            }
            window.location.href = nuevaUrl;

        }

    };

    redirectChosenLanguage();

};
