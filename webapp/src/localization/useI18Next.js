import api from "../api";
import { localStorageCache } from "../shared/localStorageHelper";
import { Logger } from "../shared/logger";
import { formatMoney } from "../shared/react/Money";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import useMountEffect from "../shared/react/useMountEffect";
import i18n from "i18next";
import Backend from "i18next-http-backend";
import _ from "lodash";
import React from "react";

const logger = new Logger("i18n.hook");

export const I18NextContext = React.createContext();

export const useI18Next = () => React.useContext(I18NextContext);
export default useI18Next;

let memoryCache = localStorageCache.getItem("language", "en");

export function getCurrentLanguage() {
  return memoryCache;
}

export function I18NextProvider({ children }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const [language, setLanguage] = useLocalStorageState("language", "en");

  const changeLanguage = React.useCallback(
    (lang) => {
      api
        .changeLanguage({ language: lang })
        .then(_.noop)
        .catch((r) => logger.error(r));
      setI18NextLoading(true);
      Promise.delayOr(
        500,
        i18n.changeLanguage(lang).then(() => {
          setLanguage(lang);
          memoryCache = lang;
        })
      ).then(() => {
        setI18NextLoading(false);
      });
    },
    [setLanguage]
  );

  useMountEffect(() => {
    i18n
      .use(Backend)
      .init({
        ns: ["strings"],
        // Disable fallback language for now so it's easy to see when translations are missing.
        fallbackLng: false,
        initImmediate: false,
        lng: language,
        backend: {
          loadPath: `${process.env.PUBLIC_URL}/locale/{{lng}}/{{ns}}.json`,
        },
        interpolation: {
          // react already safes from xss
          escapeValue: false,
        },
      })
      .finally(() => setI18NextLoading(false));
    i18n.services.formatter.add("sumaCurrency", (value, lng, options) => {
      return formatMoney(value);
    });
  });

  return (
    <I18NextContext.Provider value={{ i18nextLoading, language, changeLanguage }}>
      {children}
    </I18NextContext.Provider>
  );
}
