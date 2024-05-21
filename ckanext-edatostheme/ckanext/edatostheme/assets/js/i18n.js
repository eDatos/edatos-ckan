
window.addEventListener("load",function () {

    const SITE_URL = "FILL_SITE_URL";
    const I18N_COOKIE = "chosenLocale";

    function getObjectCookie() {
        console.log('DEBUG ~ getObjectCookie ~ getObjectCookie:',getObjectCookie)
        const separador = '; ';
        let cookies = document.cookie;
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
        return '';
    };

    function redirectChosenLanguage(language = 'es') {
        console.log('DEBUG ~ redirectChosenLanguage ~ redirectChosenLanguage:',redirectChosenLanguage)
        const language = getLocalLanguage();
        const formatedLanguage = `/${language}/`
        const currentUrl = (window.location.href);
        if (!(formatedLanguage.test(currentUrl))) {
            let languageUrl = SITE_URL.concat(language);
            window.location.href = languageUrl;
        } else {
            window.location.href = 'bing.es';
        }
    };

    redirectChosenLanguage();

});