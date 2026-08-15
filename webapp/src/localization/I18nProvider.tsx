import api from "../api";
import config from "../config.js";
import { dayjs } from "../modules/dayConfig";
import doOnce from "../modules/doOnce";
import { Logger } from "../modules/logger";
import { formatMoney } from "../modules/money";
import useMountEffect from "../state/useMountEffect";
import useUser from "../state/useUser";
import { useCurrentLanguage } from "./currentLanguage";
import i18n from "./i18n";
import noop from "lodash/noop";
import React from "react";

const logger = new Logger("i18n.hook");

interface LoadLanguageFileOptions {
  language?: string;
}

interface I18nContextValue {
  initializing: boolean;
  currentLanguage: string;
  changeLanguage: (language: string) => Promise<any> | null;
  loadLanguageFileUnsafe: (namespace: string, options?: LoadLanguageFileOptions) => any;
  loadLanguageFile: (namespace: string, options?: LoadLanguageFileOptions) => any;
}

export const I18nContext = React.createContext<I18nContextValue>({
  initializing: true,
  currentLanguage: "",
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  changeLanguage: (_lng) => null,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  loadLanguageFileUnsafe: (_ns, _opts) => null,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  loadLanguageFile: (_ns, _opts) => null,
});

export default function I18nProvider({ children }: { children: React.ReactNode }) {
  const [initializing, setInitializing] = React.useState(true);
  const [currentLanguage, setCurrentLanguage] = useCurrentLanguage();
  const { userAuthed } = useUser();

  /**
   * Same as loadLanguageFile, but the rejected promises bubbles up.
   * In general this isn't useful, since if the load fails, we just want to fall back
   * to the unlocalized string keys.
   * But in some cases we need to know if the load failed.
   */
  const loadLanguageFileUnsafe = React.useCallback(
    (namespace: string, { language }: LoadLanguageFileOptions = {}) => {
      language = language || currentLanguage;
      if (i18n.hasFile(language, namespace)) {
        return Promise.resolve();
      }
      return api
        .getLocaleFile(
          { locale: language, namespace, cachebust: config.release },
          { camelize: false, timeout: 5000 }
        )
        .then((resp) => i18n.putFile(language, namespace, resp.data))
        .tapCatch((e) =>
          logger
            .context({ error: e })
            .error(`Failed to load i18n namespace`, { language, namespace })
        );
    },
    [currentLanguage]
  );

  /**
   * Loads the given language file by making an HTTP request.
   * The promise resolves when the language file is loaded or fails to load.
   * @param namespace Name of the file, like 'strings'.
   * @param language Language ('en', 'es') or empty to use current language.
   */
  const loadLanguageFile = React.useCallback(
    (namespace: string, { language }: LoadLanguageFileOptions = {}) => {
      return loadLanguageFileUnsafe(namespace, { language }).catch(() => null);
    },
    [loadLanguageFileUnsafe]
  );

  /**
   * Change the current language by updating the user in the backend,
   * loading the language file, and changing other locale info.
   * @param language 'en', 'es', etc.
   */
  const changeLanguage = React.useCallback(
    (language: string) => {
      const promises: Promise<any>[] = [];
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
      loadLanguageFileUnsafe,
      loadLanguageFile,
    }),
    [
      changeLanguage,
      currentLanguage,
      initializing,
      loadLanguageFile,
      loadLanguageFileUnsafe,
    ]
  );

  // noinspection JSValidateTypes
  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}
