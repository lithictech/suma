import api from "../api";
import { dayjs } from "../modules/dayConfig";
import doOnce from "../shared/doOnce";
import { Logger } from "../shared/logger";
import { formatMoney } from "../shared/money";
import useMountEffect from "../shared/react/useMountEffect";
import useUser from "../state/useUser";
import { setCurrentLanguage, useCurrentLanguage } from "./currentLanguage";
import i18n from "i18next";
import Backend from "i18next-http-backend";
import noop from "lodash/noop";
import React from "react";

const logger = new Logger("i18n.hook");

export const I18NextContext = React.createContext({});

export default function I18NextProvider({ children }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const [language, setLanguage] = useCurrentLanguage();
  const { userAuthed } = useUser();
  const changeLanguage = React.useCallback(
    (lang) => {
      userAuthed &&
        api
          .changeLanguage({ language: lang })
          .then(noop)
          .catch((r) => logger.error(r));
      setI18NextLoading(true);
      Promise.delayOr(
        500,
        i18n.changeLanguage(lang).then(() => {
          setLanguage(lang);
          dayjs.locale(lang);
          setCurrentLanguage(lang);
        })
      ).then(() => {
        setI18NextLoading(false);
      });
    },
    [setLanguage, userAuthed]
  );

  useMountEffect(
    doOnce("i18ninit", () => {
      i18n
        .use(Backend)
        .init({
          ns: ["strings"],
          // Disable fallback language for now so it's easy to see when translations are missing.
          fallbackLng: false,
          initImmediate: false,
          lng: language,
          backend: {
            loadPath: `/locale/{{lng}}/{{ns}}.json`,
          },
          interpolation: {
            // react already safes from xss
            escapeValue: false,
          },
        })
        .finally(() => setI18NextLoading(false));
      i18n.services.formatter.add("sumaCurrency", (value) => {
        return formatMoney(value);
      });
    })
  );

  const value = React.useMemo(
    () => ({ i18nextLoading, language, changeLanguage }),
    [changeLanguage, i18nextLoading, language]
  );

  return <I18NextContext.Provider value={value}>{children}</I18NextContext.Provider>;
}
