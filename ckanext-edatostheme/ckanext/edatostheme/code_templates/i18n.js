window.onload = function () {

    const SITE_URL = "FILL_SITE_URL";
    const REGEXP_SITE_URL = "FILL_REGEXP_SITE_URL";
    console.log('DEBUG ~ REGEXP_SITE_URL ~ REGEXP_SITE_URL:',REGEXP_SITE_URL);
    const I18N_COOKIE = "chosenLocale";

    function getObjectCookie() {
        console.log('DEBUG ~ getObjectCookie ~ getObjectCookie:',getObjectCookie);
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
        console.log('DEBUG ~ getLocalLanguage ~ getLocalLanguage:',getLocalLanguage);
        let cookieObject = getObjectCookie();
        if (cookieObject.hasOwnProperty(I18N_COOKIE)) {
            console.log('DEBUG ~ getLocalLanguage ~ getObjectCookie.chosenLocale:',cookieObject.chosenLocale);
            return cookieObject.chosenLocale;
        }

        return typeof Edatos !== 'undefined' && typeof Edatos.i18n.getDefaultLanguage !== 'undefined' ? Edatos.i18n.getDefaultLanguage() : 'es';
    };

    function breakAddress(url) {
        console.log('DEBUG ~ breakAddress ~ url:',url);

        // home
        //const SITE_URL = "https://estadisticas.arte-consultores.com/catalogo/";

        // navegando en español
        // https://estadisticas.arte-consultores.com/catalogo/es/dataset/urn-sdmx-org-sdmx-infomodel-conceptscheme-conceptscheme-istac-esquema_vacio

        // https:// estadisticas.arte-consultores.com/catalogo

        var data = url.split(SITE_URL);
        var domain = data[0];

        // Comprobar hay path y devolver el resto de la dirección
        data = data[1].split("/");
        var language = data[0];
        if (data[1]) {
            return [domain,language,data.slice(1).join("/")];
        }

        return [domain,language];
    }

    function redirectChosenLanguage(language = 'es') {
        console.log('DEBUG ~ redirectChosenLanguage ~ redirectChosenLanguage:',redirectChosenLanguage);
        language = getLocalLanguage();

        let regexLang = `^${REGEXP_SITE_URL}(${language}(\/.*|$))([^/.]+)?$`;
        regexLang = new RegExp(regexLang,'i');
        const currentUrl = new URL(window.location.href);

        console.log('DEBUG ~ redirectChosenLanguage ~ currentUrl:',currentUrl);
        console.log('DEBUG ~ redirectChosenLanguage ~ regexLang:',regexLang);

        const path = currentUrl.href;
        console.log('DEBUG ~ redirectChosenLanguage ~ path:',path);

        //let languageUrl = SITE_URL.concat(language);
        console.log('DEBUG ~ redirectChosenLanguage ~ regexLang.test(regexLang):',regexLang.test(path));

        var urlArray = breakAddress(path);
        //if (regexLang.test(path) !== true) {
        var nuevaUrl = '';
        if (urlArray[1] !== language) {
            //console.log('DEBUG ~ redirectChosenLanguage ~ languageUrl:',languageUrl);
            if (urlArray[2] !== undefined) {
                nuevaUrl = SITE_URL.concat(language,"/",urlArray[2]);
            }
            nuevaUrl = SITE_URL.concat(language,"/");
            console.log('DEBUG ~ redirectChosenLanguage ~ concatUrl:',concatUrl)
            console.log('DEBUG ~ redirectChosenLanguage ~ breakAddress(path);:',breakAddress(path))
            window.location.href = nuevaUrl;
        } else {
            console.log('DEBUG ~ redirectChosenLanguage ~ DEBUG:',"NOTHING HERE");
        }

    };

    redirectChosenLanguage();

};
