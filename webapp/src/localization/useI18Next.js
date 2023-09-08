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
      key = key.replace("strings:", "").replace(":", ".");
      const string = get(strings, key);

      if (!string) {
        console.error(`${key} was not found in strings`);
        return key;
      }
      // TODO: Ensure translate deep '$t(string:ns)' translations in strings, all the time
      //  before returning
      if (isEmpty(dynamicValuesObj)) {
        return string;
      }

      return convertDynamicValues(string, dynamicValuesObj);
    },
    [strings]
  );

  const value = React.useMemo(
    () => ({ i18nextLoading, language, changeLanguage, t }),
    [changeLanguage, i18nextLoading, language, t]
  );

  return <I18NextContext.Provider value={value}>{children}</I18NextContext.Provider>;
}

function convertDynamicValues(string, dynamicValuesObj) {
  const stringDynamicVals = [];
  let dynamicStringParts = string.split("{{");
  dynamicStringParts.shift();
  dynamicStringParts.forEach((dynStr) => {
    stringDynamicVals.push(first(dynStr.split("}}")));
  });

  const dynValuesLength =
    Object.keys(dynamicValuesObj).includes("externalLinks") &&
    Object.keys(dynamicValuesObj).length - 1;
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
    resultString = resultString.replace(`{{${val}}}`, dynamicValuesObj[val]);
  });
  return resultString;
}
