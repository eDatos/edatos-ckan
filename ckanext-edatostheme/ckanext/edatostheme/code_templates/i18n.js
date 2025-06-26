window.onload = function () {

    const SITE_URL = "FILL_SITE_URL";
    const I18N_COOKIE = "chosenLocale";
    const SITE_LANGUAGES = "FILL_SITE_LANGUAGES";

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
        if (!url.startsWith(SITE_URL)) return [url,null,null];

        let path = url.slice(SITE_URL.length);
        let segments = path.split("/").filter(Boolean);

        let language = null;
        let rest = [];
        if (SITE_LANGUAGES.split(' ').includes(segments[0])) {
            language = segments[0];
            rest = segments.slice(1);
        } else {
            rest = segments;
        }

        return [SITE_URL,language,rest.join("/")];
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

