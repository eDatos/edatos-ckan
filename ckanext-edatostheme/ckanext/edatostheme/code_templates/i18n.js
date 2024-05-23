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
        // return 'es';
        return typeof Edatos !== 'undefined' && typeof Edatos.i18n.getDefaultLanguage !== 'undefined' ? Edatos.i18n.getDefaultLanguage() : 'es';
    };

    function redirectChosenLanguage(language = 'es') {
        console.log('DEBUG ~ redirectChosenLanguage ~ redirectChosenLanguage:',redirectChosenLanguage);
        language = getLocalLanguage();


        // const regexLang = new RegExp(`/${language}/`);
        // const currentUrl = (window.location.href);
        // if (!(regexLang.test(currentUrl))) {
        //     let languageUrl = SITE_URL.concat(language);
        //     window.location.href = languageUrl;
        // }
        // const regexLang = '/'.concat(language);

        // site_url = "https://estadisticas.arte-consultores.com/catalogo/ru"
        // REGEXP_SITE_URL = "https:\/\/estadisticas\.arte-consultores\.com\/catalogo\/ru"

        // let regexLang = new RegExp(`^${REGEXP_SITE_URL}(${language}(\/.*|$))([^\/.]+)?$`);
        let regexLang = `/^${REGEXP_SITE_URL}(${language}(\/.*|$))([^/.]+)?$/`;
        regexLang = new RegExp(regexLang,'i');
        const currentUrl = new URL(window.location.href);
        console.log('DEBUG ~ redirectChosenLanguage ~ currentUrl:',currentUrl);
        console.log('DEBUG ~ redirectChosenLanguage ~ regexLang:',regexLang);
        const path = currentUrl.href;
        console.log('DEBUG ~ redirectChosenLanguage ~ path:',path);
        let languageUrl = SITE_URL.concat(language);
        console.log('DEBUG ~ redirectChosenLanguage ~ regexLang.test(regexLang):',regexLang.test(path));
        if (regexLang.test(path) !== true) {
            // if (!path.indexOf(regexLang)) {
            // console.log('DEBUG ~ redirectChosenLanguage ~ path.indexOf(regexLang:',path.indexOf(regexLang));
            console.log('DEBUG ~ redirectChosenLanguage ~ languageUrl:',languageUrl);
            window.location.href = languageUrl;
        }

    };

    redirectChosenLanguage();

};