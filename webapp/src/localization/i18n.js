import { withSentry } from "../shared/sentry.js";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";

class I18n {
  constructor() {
    this.cache = {};
    this.formatters = {};
    this.language = "";
    this.debugStaticStrings = new URLSearchParams(window.location.search).has(
      "debugstaticstrings"
    );
  }

  /**
   * Register a formatter.
   * For example, the localized string "amount: {{amount, currency}}",
   * would use the "currency" formatter.
   * @param {string} key Identify the formatter (ie, "currency").
   * @param {function} func Called with the resolved value.
   */
  addFormatter = (key, func) => {
    this.formatters[key] = func;
  };

  /**
   * When a formatted strings file is loaded (see i18n.rb), add it here.
   * @param {string} language like "en", "es", etc.
   * @param {string} namespace name of the file ("strings")
   * @param {object} body Contents of the loaded file.
   */
  putFile = (language, namespace, body) => {
    if (!this.language) {
      this.language = language;
    }
    const strings = this.cache[language] || {};
    strings[namespace] = body;
    this.cache[language] = strings;
  };

  /**
   * Return true if the file has been added.
   * See `putFile`.
   * @param {string} language
   * @param {string} namespace
   * @returns {boolean}
   */
  hasFile = (language, namespace) => {
    const strings = this.cache[language];
    if (!strings) {
      return false;
    }
    if (!strings[namespace]) {
      return false;
    }
    return true;
  };

  /**
   * Given a localization key like "strings.dashboard.hello",
   * return the "formatter" (m, mp, s) and the localized string
   * with values templated in. Like i18next.t,
   * but with markdown formatting info.
   * @param {string} key Full key, like 'strings.navigation.title'.
   * @param {object} opts Options to pass to the interpolator.
   *   For example, a string like "Hello, {{name}}" would be called with
   *   `t("dashboard.greeting", {name: user.name})`.
   * @returns {Array<string>} Tuple of the formatter ("m", "mp", or "s")
   *   and the resolved string.
   */
  resolve = (key, opts) => {
    if (this.debugStaticStrings) {
      return ["s", key];
    }
    const fqn = this.fqn(key);
    const value = get(this.cache, fqn);
    if (!value) {
      if (!isEmpty(this.cache) && !alertedMissingFqns[fqn]) {
        // If the key isn't found, use string formatting on the key.
        // Do not warn if this happens while we're still initializing languages
        // (cache is empty until first file is loaded).
        console.log(
          `localization key '${fqn}' not found, static string must be added`,
          this.cache
        );
        console.trace();
        withSentry((sentry) => {
          sentry.withScope((scope) => {
            scope.setLevel("warning");
            scope.setTags({
              localization_key_fqn: fqn,
              localization_key: key,
              localization_language: this.language,
            });
            sentry.captureMessage("missing_localization_key");
          });
        });
        alertedMissingFqns[fqn] = true;
      }
      return ["s", key];
    }
    // eslint-disable-next-line no-unused-vars
    const [formatter, template, ...locOpts] = value;
    let finalStr = template;
    locOpts.forEach(({ k, f, t }) => {
      let resolved;
      if (t) {
        // This is a pointer to another string, like $t(xyz).
        // Resolve t('xyz') and substitute a placeholder.
        resolved = this.t(t, opts);
      } else {
        // This is a value lookup, like {{x}} should get opts.x
        resolved = get(opts, k);
        if (f) {
          const formatter = this.formatters[f];
          if (!formatter) {
            console.error("invalid formatter", f);
          } else {
            resolved = formatter(resolved);
          }
        }
      }
      finalStr = finalStr.replace("@%", resolved);
    });
    return [formatter, finalStr];
  };

  formatter = (key) => {
    const fqn = this.fqn(key, "0");
    return get(this.cache, fqn);
  };

  t = (key, opts) => {
    const [, str] = this.resolve(key, opts);
    return str;
  };

  fqn = (...args) => {
    const suffix = args.join(".");
    const fqn = `${this.language}.${suffix}`;
    return fqn;
  };
}

const instance = new I18n();
export default instance;
window.i18n = instance;

const alertedMissingFqns = {};
