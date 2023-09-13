import { formatMoney } from "../shared/react/Money";
import first from "lodash/first";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";

class sumaTranslator {
  constructor() {
    this.ns = "strings";
    this.lng = "en";
    this.path = `${process.env.PUBLIC_URL}/locale/${this.lng}/${this.ns}.json`;
    this.strings = {};
  }

  async init(ns, lng) {
    this.ns = ns;
    this.lng = lng;

    return await fetch(`${process.env.PUBLIC_URL}/locale/${lng}/${ns}.json`)
      .then((r) => r.json())
      .then(async (strings) => {
        this.strings = strings;
        return await strings;
      });
  }

  t = (key, options = {}) => {
    const string = stringByKey(this.strings, key);

    if (!string && !isEmpty(this.strings)) {
      console.error(`${key} was not found in strings`);
      return key;
    } else if (!string) {
      return key;
    }

    const translatedKeysString = translateKeys({
      stings: this.strings,
      string,
    });
    if (!isEmpty(options)) {
      return translateDynamicValues({
        string: translatedKeysString,
        options,
      });
    }
    return translatedKeysString;
  };
}
export default new sumaTranslator();

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
function translateDynamicValues({ string, options }) {
  const dynamicPrefix = "{{";
  const dynamicSuffix = "}}";

  if (!string.includes(dynamicPrefix)) {
    return string;
  }

  const stringDynamicVals = getStringDynamicValues(string, dynamicPrefix, dynamicSuffix);

  const dynValuesLength = Object.keys(options).includes("externalLinks")
    ? Object.keys(options).length - 1
    : Object.keys(options).length;
  if (stringDynamicVals.length > dynValuesLength) {
    console.error(
      `'${string}' requires ${stringDynamicVals.length} dynamic values but only ${dynValuesLength} were provided`
    );
  }

  let resultString = string;
  stringDynamicVals.forEach((val) => {
    if (val.includes("sumaCurrency")) {
      let valArr = val.split(",");
      valArr.pop();
      // set formatted value to be replaced
      options[val] = formatMoney(options[valArr[0]]);
      // delete unused property
      delete options[valArr[0]];
    }
    resultString = resultString.replace(
      `${dynamicPrefix + val + dynamicSuffix}`,
      options[val]
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
  key = key.replace("strings:", "").replace(".", ":").split(":");
  return get(strings, key);
}
