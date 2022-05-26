import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import HttpApi from "i18next-http-backend";

i18n
  .use(LanguageDetector)
  .use(HttpApi)
  .init({
    ns: ["common", "dashboard", "errors", "mobility", "messages", "forms"],
    fallbackLng: "en",
    initImmediate: false,
    detection: {
      order: ["htmlTag", "localStorage", "cookie"],
      caches: ["cookie"],
    },
    backend: {
      loadPath: "/locale/{{lng}}/{{ns}}.json",
    },
    interpolation: {
      // react already safes from xss
      escapeValue: false,
    },
    react: {
      useSuspense: false,
    },
  });

export default i18n;
