import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import Backend from "i18next-http-backend";

i18n
  .use(Backend)
  .use(LanguageDetector)
  .init({
    initImmediate: false,
    detection: {
      order: ["htmlTag", "localStorage", "cookie"],
      caches: ["cookie"],
    },
    fallbackLng: "en",
    ns: ["common", "dashboard", "errors", "mobility", "messages", "forms"],
    backend: {
      loadPath: "/locale/{{lng}}/{{ns}}.json",
    },
    interpolation: {
      // react already safes from xss
      escapeValue: false,
    },
  });

export default i18n;
