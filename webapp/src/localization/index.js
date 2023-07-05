import SumaMarkdown from "../components/SumaMarkdown";
import externalLinks from "../modules/externalLinks";
import { Logger } from "../shared/logger";
import i18n from "i18next";
import { compiler } from "markdown-to-jsx";
import React from "react";
import ReactDOM from "react-dom";

const runChecks = process.env.NODE_ENV === "development";

const logger = new Logger("i18n");

export class Lookup {
  constructor(prefix) {
    this.prefix = prefix + ":";
  }
  /**
   * Render markdown localization strings.
   * Generally you want to use `md` or `mdp` instead
   * of `mdx` (which takes options for the markdown and i18n calls).
   * We have these two helpers because in most cases
   * we do not want the surrounding `p` tags for the text
   * we are rendering, except when we have newlines.
   *
   * If your markdown has newlines, it must use p tags to
   * get the newlines to render, so use `mdp`:
   *
   *   <h1>title</h1>
   *   {mdp("key")}
   *
   * Will render:
   *
   *   <h1>title</h1>
   *   <p>line1</p>
   *   <p>line2</p>
   *
   * If you do not have newlines, use `md` which is used like:
   *
   *   <h1>title</h1>
   *   <p>{md("key")}</p>
   *
   * Note: Links are rendered with the ELink component,
   * which will 1) use a new tab for external links,
   * 2) use Link for internal links (# or /),
   * and 3) use a Link with 'replace' if the href includes ##.
   * So ## can be used, for example, to trigger modals controlled by the hash.
   */
  mdx = (key, mdoptions = {}, i18noptions = {}) => {
    const { check, ...i18nrest } = i18noptions;
    const str = i18n.t(this.prefix + key, { ...i18nrest, externalLinks });
    if (check && runChecks) {
      this.checkKeyName(key);
      compileStringAsync(str, (s) => {
        if (s && str && s === str) {
          logger
            .context({ key: key, input: str, output: s })
            .error("used localization.mdx for a non-string value (slow)");
        }
      });
    }
    return <SumaMarkdown options={mdoptions}>{str}</SumaMarkdown>;
  };

  md = (key, options = {}) => {
    return this.mdx(key, { forceWrapper: true, wrapper: React.Fragment }, options);
  };

  mdp = (key, options = {}) => {
    return this.mdx(key, { forceBlock: true }, options);
  };

  t = (key, options = {}) => {
    const { check, ...restopts } = options;
    const str = i18n.t(this.prefix + key, restopts);
    if (check && runChecks) {
      this.checkKeyName(key);
      compileStringAsync(str, (s) => {
        if (s && str && s !== str) {
          logger
            .context({ key: key, input: str, output: s })
            .error("used localization.t for a markdown string");
        }
      });
    }
    return str;
  };

  checkKeyName(key) {
    if (key.startsWith(this.prefix)) {
      logger
        .context({ string_key: key })
        .error(
          `Do not start localization keys with '${this.prefix}', since it may change in the future.`
        );
    }
  }
}

const lu = new Lookup("strings");
export const t = lu.t;
export const md = lu.md;
export const mdp = lu.mdp;
export const mdx = lu.mdx;

function compileStringAsync(str, cb) {
  window.setTimeout(() => {
    const comp = compiler(str || "", { wrapper: React.Fragment, forceWrapper: true });
    const el = document.createElement("div");
    ReactDOM.render(comp, el, () => cb(el.innerHTML));
  }, 0);
}
