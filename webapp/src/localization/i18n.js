import format from "./i18n-format";
import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import HttpApi from "i18next-http-backend";
import { initReactI18next } from "react-i18next";

i18n
  .use(initReactI18next)
  .use(LanguageDetector)
  .use(HttpApi)
  .init({
    ns: ["common", "errors"],
    fallbackLng: "en",
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
      format,
    },
    react: {
      useSuspense: false,
    },
  });

export default i18n;
