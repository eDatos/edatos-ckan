(function () {

    const SITE_URL = "FILL_SITE_URL";
    const I18N_COOKIE = "chosenLocale";

    function getObjectCookie() {
        console.log('DEBUG ~ getObjectCookie ~ getObjectCookie:',getObjectCookie)
        const separador = '; ';
        let cookies = document.cookie
        let objCookies = Object.fromEntries(
            cookies
                .split(separador)
                .map(
                    c => c.split('=')
                ))

        return objCookies
    };

    function getLocalLanguage() {
        console.log('DEBUG ~ getLocalLanguage ~ getLocalLanguage:',getLocalLanguage)
        let cookieObject = getObjectCookie()
        if (cookieObject.hasOwnProperty(I18N_COOKIE)) {
            console.log('DEBUG ~ getLocalLanguage ~ getObjectCookie.chosenLocale:',cookieObject.chosenLocale)
            return cookieObject.chosenLocale
        }
        return 'es';
        // return typeof Edatos !== 'undefined' && typeof Edatos.i18n.getDefaultLanguage !== 'undefined' ? Edatos.i18n.getDefaultLanguage() : 'es';
    };

    function redirectChosenLanguage(language = 'es') {
        console.log('DEBUG ~ redirectChosenLanguage ~ redirectChosenLanguage:',redirectChosenLanguage)
        language = getLocalLanguage();


        // const regexLang = new RegExp(`/${language}/`);
        // const currentUrl = (window.location.href);
        // if (!(regexLang.test(currentUrl))) {
        //     let languageUrl = SITE_URL.concat(language);
        //     window.location.href = languageUrl;
        // }
        // const regexLang = '/'.concat(language);
        // /^https:\/\/estadisticas\.arte-consultores\.com\/catalogo\/(ca(\/.*|$))([^\/.]+)?$
        site_rul = "https://estadisticas.arte-consultores.com/catalogo/ru"

        const siteUrlRegex = SITE_URL.replace('/','\/').replace('.','\.');
        let regexLang = new RegExp(`/^${siteUrlRegex}\/${language}(\/.*|$))([^\/.]+)?/$`);

        // const regexLang = new RegExp(`/^\/${language}($|\/|-)/`);
        const currentUrl = new URL(window.location.href);
        console.log('DEBUG ~ redirectChosenLanguage ~ currentUrl:',currentUrl)
        console.log('DEBUG ~ redirectChosenLanguage ~ regexLang:',regexLang)
        const path = currentUrl.href;
        console.log('DEBUG ~ redirectChosenLanguage ~ path:',path)
        // if (!regexLang.test(path)) {
        if (path.indexOf(regexLang)) {
            console.log('DEBUG ~ redirectChosenLanguage ~ path.indexOf(regexLang:',path.indexOf(regexLang));
            let languageUrl = SITE_URL.concat(language);
            console.log('DEBUG ~ redirectChosenLanguage ~ languageUrl:',languageUrl)
            window.location.href = languageUrl;
        }

    };

    redirectChosenLanguage();

}());