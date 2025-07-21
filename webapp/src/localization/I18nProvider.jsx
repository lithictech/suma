import api from "../api";
import config from "../config.js";
import { dayjs } from "../modules/dayConfig";
import doOnce from "../shared/doOnce";
import { Logger } from "../shared/logger";
import { formatMoney } from "../shared/money";
import useMountEffect from "../shared/react/useMountEffect";
import useUser from "../state/useUser";
import { useCurrentLanguage } from "./currentLanguage";
import i18n from "./i18n";
import noop from "lodash/noop";
import React from "react";

const logger = new Logger("i18n.hook");

export const I18nContext = React.createContext({
  initializing: true,
  currentLanguage: "",
  // eslint-disable-next-line no-unused-vars
  changeLanguage: (_lng) => null,
  // eslint-disable-next-line no-unused-vars
  loadLanguageFile: (_ns, _opts) => null,
});

export default function I18nProvider({ children }) {
  const [initializing, setInitializing] = React.useState(true);
  const [currentLanguage, setCurrentLanguage] = useCurrentLanguage();
  const { userAuthed } = useUser();

  /**
   * Loads the given language file by making an HTTP request.
   * The promise resolves when the language file is loaded.
   * @param {string} namespace Name of the file, like 'strings'.
   * @param {string} language Language ('en', 'es') or empty to use current language.
   * @return {Promise}
   */
  const loadLanguageFile = React.useCallback(
    (namespace, { language } = {}) => {
      language = language || currentLanguage;
      if (i18n.hasFile(language, namespace)) {
        return Promise.resolve();
      }
      return api
        .getLocaleFile(
          { locale: language, namespace, cachebust: config.release },
          { camelize: false }
        )
        .then((resp) => i18n.putFile(language, namespace, resp.data))
        .catch((e) =>
          logger
            .context({ error: e })
            .error(`Failed to load i18n namespace`, { language, namespace })
        );
    },
    [currentLanguage]
  );

  /**
   * Change the current language by updating the user in the backend,
   * loading the language file, and changing other locale info.
   * @param {string} language 'en', 'es', etc.
   * @return {Promise} Resolves when the language is changed.
   */
  const changeLanguage = React.useCallback(
    (language) => {
      const promises = [];
      if (userAuthed) {
        promises.push(
          api
            .changeLanguage({ language })
            .then(noop)
            .catch((r) => logger.error(r))
        );
      }
      promises.push(
        Promise.delayOr(
          500,
          loadLanguageFile("strings", { language }).then(() => {
            setCurrentLanguage(language);
            i18n.language = language;
            dayjs.locale(language);
          })
        )
      );
      return Promise.all(promises);
    },
    [loadLanguageFile, setCurrentLanguage, userAuthed]
  );

  // When the app is loaded, load the first strings file.
  useMountEffect(
    doOnce("i18ninit", () => {
      loadLanguageFile("strings").finally(() => setInitializing(false));
      i18n.language = currentLanguage;
      i18n.addFormatter("sumaCurrency", (v) => formatMoney(v));
    })
  );

  const value = React.useMemo(
    () => ({
      initializing,
      currentLanguage,
      changeLanguage,
      loadLanguageFile,
    }),
    [changeLanguage, currentLanguage, initializing, loadLanguageFile]
  );

  // noinspection JSValidateTypes
  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}
