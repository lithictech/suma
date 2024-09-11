import get from "lodash/get";

class I18n {
  constructor() {
    this.cache = {};
    this.formatters = {};
    this.language = "";
  }

  /**
   * Register a formatter.
   * For example, the localized string "amount: {{amount, currency}}",
   * would use the "currency" formatter.
   * @param {string} key Identify the formatter (ie, "currency").
   * @param {function} func Called with the resolved value.
   */
  addFormatter(key, func) {
    this.formatters[key] = func;
  }

  /**
   * When a formatted strings file is loaded (see i18n.rb), add it here.
   * @param {string} language like "en", "es", etc.
   * @param {string} namespace name of the file ("strings")
   * @param {object} body Contents of the loaded file.
   */
  putFile(language, namespace, body) {
    if (!this.language) {
      this.language = language;
    }
    const strings = this.cache[language] || {};
    strings[namespace] = body;
    this.cache[language] = strings;
  }

  /**
   * Return true if the file has been added.
   * See `putFile`.
   * @param {string} language
   * @param {string} namespace
   * @returns {boolean}
   */
  hasFile(language, namespace) {
    const strings = this.cache[language];
    if (!strings) {
      return false;
    }
    if (!strings[namespace]) {
      return false;
    }
    return true;
  }

  /**
   * Given a localization key like "strings.dashboard.hello",
   * return the "formatter" (m, mp, s) and the localized string
   * with values templated in. Like i18next.t,
   * but with markdown formatting info.
   * @param {string} key Full key, like 'strings.navigation.title'.
   * @param {object} opts Options to pass to the interpolator.
   *   For example, a string like "Hello, {{name}}" would be called with
   *   `t("dashboard.greeting", {name: user.name})`.
   * @returns {*|*[]} Tuple of the formatter ("m", "mp", or "s")
   *   and the resolved string.
   */
  resolve(key, opts) {
    const fqn = this.fqn(key);
    const value = get(this.cache, fqn);
    if (!value) {
      return key;
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
  }

  formatter(key) {
    const fqn = this.fqn(key, "0");
    return get(this.cache, fqn);
  }

  t(key, opts) {
    const [, str] = this.resolve(key, opts);
    return str;
  }

  fqn(...args) {
    // TODO: Delete this (and add a check)
    // when we're ready to mass-update all localization keys.
    // The 'convert : to ,' causes a lot of extra string copies.
    args = [...args].map((x) => x?.replaceAll(":", "."));
    const suffix = args.join(".");
    const fqn = `${this.language}.${suffix}`;
    return fqn;
  }
}

const instance = new I18n();
export default instance;
window.i18n = instance;
