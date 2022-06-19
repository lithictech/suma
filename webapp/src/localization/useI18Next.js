import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import Backend from "i18next-http-backend";
import React from "react";

export default function useI18Next() {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  React.useEffect(() => {
    i18n
      .use(LanguageDetector)
      .use(Backend)
      .init({
        ns: [
          "common",
          "dashboard",
          "errors",
          "ledgerusage",
          "mobility",
          "messages",
          "forms",
          "payments",
        ],
        // Disable fallback language for now so it's easy to see when translations are missing.
        // fallbackLng: "en",
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
      })
      .finally(() => setI18NextLoading(false));
  }, []);
  return { i18nextLoading };
}
