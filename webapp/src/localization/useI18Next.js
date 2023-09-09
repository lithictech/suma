import api from "../api";
import { dayjs } from "../modules/dayConfig";
import doOnce from "../shared/doOnce";
import { Logger } from "../shared/logger";
import { formatMoney } from "../shared/react/Money";
import useMountEffect from "../shared/react/useMountEffect";
import { useUser } from "../state/useUser";
import { setCurrentLanguage, useCurrentLanguage } from "./currentLanguage";
import i18n from "i18next";
import Backend from "i18next-http-backend";
import first from "lodash/first";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";
import noop from "lodash/noop";
import React from "react";

const logger = new Logger("i18n.hook");

export const I18NextContext = React.createContext();

export const useI18Next = () => React.useContext(I18NextContext);
export default useI18Next;

export function I18NextProvider({ children }) {
  const [i18nextLoading, setI18NextLoading] = React.useState(true);
  const [language, setLanguage] = useCurrentLanguage();
  const { userAuthed } = useUser();
  const [strings, setStrings] = React.useState({});
  const defaultNS = "strings";

  const fetchStrings = React.useCallback((lang) => {
    fetch(`${process.env.PUBLIC_URL}/locale/${lang}/${defaultNS}.json`)
      .then((r) => r.json())
      .then((strings) => {
        setStrings(strings);
      });
  }, []);

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
          fetchStrings(lang);
        })
      ).then(() => {
        setI18NextLoading(false);
      });
    },
    [setLanguage, userAuthed, fetchStrings]
  );

  useMountEffect(
    doOnce("i18ninit", () => {
      fetchStrings(language);
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
    })
  );

  const t = React.useCallback(
    (key, dynamicValuesObj) => {
      dynamicValuesObj = dynamicValuesObj || {};
      const string = stringByKey(strings, key);
      if (!string) {
        console.error(`${key} was not found in strings`);
        return key;
      }
      const translatedKeysString = translateKeys({
        strings,
        string,
      });
      if (!isEmpty(dynamicValuesObj)) {
        return translateDynamicValues({
          string: translatedKeysString,
          dynamicValuesObj,
        });
      }
      return translatedKeysString;
    },
    [strings]
  );

  const value = React.useMemo(
    () => ({ i18nextLoading, language, changeLanguage, t }),
    [changeLanguage, i18nextLoading, language, t]
  );

  return <I18NextContext.Provider value={value}>{children}</I18NextContext.Provider>;
}

/**
 * Translates keys inside a localized string until there are no keys to
 * translate.
 *
 * It is called recursively until the result string does not include the
 * *dynamicPrefix* value e.g. "$t(", which indicates that there are still more
 * keys to be translated.
 *
 * Example with beginning localized string (1):
 *  (First string) "Error: $t(strings:errors:unhandled_error)".
 *  (Final result) "Error: Sorry, something went wrong. Please try again."
 *
 * @param strings All fetched strings from public folder
 * @param string String to be translated
 * @returns {string}
 */
function translateKeys({ strings, string }) {
  const dynamicPrefix = "$t(";
  const dynamicSuffix = ")";
  if (string.includes(dynamicPrefix)) {
    const stringDynamicKeys = getStringDynamicValues(
      string,
      dynamicPrefix,
      dynamicSuffix
    );
    let resultString = string;
    stringDynamicKeys.forEach((key) => {
      const newValue = stringByKey(strings, key);
      resultString = resultString.replace(dynamicPrefix + key + dynamicSuffix, newValue);
    });
    return translateKeys({ strings, string: resultString });
  }
  return string;
}

/**
 * Translated all dynamic values of a localized string based on the
 * dynamicValuesObj, for example:
 *
 * String: "Hi, my name is {{name}}" and dynamicValuesObj { name: "Juan" }
 *
 * Result: "Hi, my name is Juan"
 *
 * @param string String to be translated
 * @param dynamicValuesObj Dynamic values to be replaced inside of string
 * @returns {*}
 */
function translateDynamicValues({ string, dynamicValuesObj }) {
  const dynamicPrefix = "{{";
  const dynamicSuffix = "}}";

  if (!string.includes(dynamicPrefix)) {
    return string;
  }

  const stringDynamicVals = getStringDynamicValues(string, dynamicPrefix, dynamicSuffix);
  const dynValuesLength = Object.keys(dynamicValuesObj).includes("externalLinks")
    ? Object.keys(dynamicValuesObj).length - 1
    : Object.keys(dynamicValuesObj).length;
  if (stringDynamicVals.length !== dynValuesLength) {
    console.error(`Length of dynamic values do not match in '${string}'`);
  }

  let resultString = string;
  stringDynamicVals.forEach((val) => {
    if (val.includes("sumaCurrency")) {
      let valArr = val.split(",");
      valArr.pop();
      // set formatted value to be replaced
      dynamicValuesObj[val] = formatMoney(dynamicValuesObj[valArr[0]]);
      // delete unused property
      delete dynamicValuesObj[valArr[0]];
    }
    resultString = resultString.replace(
      `${dynamicPrefix + val + dynamicSuffix}`,
      dynamicValuesObj[val]
    );
  });
  return resultString;
}

function getStringDynamicValues(string, start, end) {
  const stringDynamicVals = [];
  let dynamicStringParts = string.split(start);
  dynamicStringParts.shift();
  dynamicStringParts.forEach((dynStr) => {
    stringDynamicVals.push(first(dynStr.split(end)));
  });
  return stringDynamicVals;
}

function stringByKey(strings, key) {
  key = key.replace("strings:", "").split(":");
  return get(strings, key);
}
