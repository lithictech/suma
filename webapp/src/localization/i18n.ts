import { formatMoney } from "../modules/money.ts";
import { withSentry } from "../modules/sentry";
import get from "lodash/get";
import isEmpty from "lodash/isEmpty";

declare global {
  interface Window {
    i18n?: I18n;
  }
}

interface LocOpt {
  k?: string;
  f?: string;
  t?: string;
}

class I18n {
  cache: Record<string, Record<string, any>> = {};
  formatters: Record<string, (value: any) => any> = {};
  language = "";
  debugStaticStrings: boolean;

  constructor() {
    this.debugStaticStrings = new URLSearchParams(window.location.search).has(
      "debugstaticstrings"
    );
  }

  /**
   * Register a formatter.
   * For example, the localized string "amount: {{amount, currency}}",
   * would use the "currency" formatter.
   * @param key Identify the formatter (ie, "currency").
   * @param func Called with the resolved value.
   */
  addFormatter = (key: string, func: (value: any) => any) => {
    this.formatters[key] = func;
  };

  addFormatters = () => {
    this.addFormatter("sumaCurrency", (v: Money) => formatMoney(v));
  };

  /**
   * When a formatted strings file is loaded (see i18n.rb), add it here.
   * @param language like "en", "es", etc.
   * @param namespace name of the file ("strings")
   * @param body Contents of the loaded file.
   */
  putFile = (language: string, namespace: string, body: any) => {
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
   */
  hasFile = (language: string, namespace: string): boolean => {
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
   * @param key Full key, like 'strings.navigation.title'.
   * @param opts Options to pass to the interpolator.
   *   For example, a string like "Hello, {{name}}" would be called with
   *   `t("dashboard.greeting", {name: user.name})`.
   * @returns Tuple of the formatter ("m", "mp", or "s") and the resolved string.
   */
  resolve = (key: string, opts?: Record<string, any>): [string, string] => {
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
          JSON.stringify(this.cache)
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
    const [formatter, template, ...locOpts] = value as any[];
    let finalStr = template;
    locOpts.forEach(({ k, f, t }: LocOpt) => {
      let resolved;
      if (t) {
        // This is a pointer to another string, like $t(xyz).
        // Resolve t('xyz') and substitute a placeholder.
        resolved = this.t(t, opts);
      } else {
        // This is a value lookup, like {{x}} should get opts.x
        resolved = get(opts, k || "");
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

  formatter = (key: string) => {
    const fqn = this.fqn(key, "0");
    return get(this.cache, fqn);
  };

  t = (key: string, opts?: Record<string, any>): string => {
    const [, str] = this.resolve(key, opts);
    return str;
  };

  fqn = (...args: string[]): string => {
    const suffix = args.join(".");
    const fqn = `${this.language}.${suffix}`;
    return fqn;
  };
}

const instance = new I18n();
export default instance;
window.i18n = instance;

const alertedMissingFqns: Record<string, boolean> = {};
