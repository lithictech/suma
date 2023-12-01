import SumaMarkdown from "../components/SumaMarkdown";
import externalLinks from "../modules/externalLinks";
import { Logger } from "../shared/logger";
import i18n from "i18next";
import { compiler } from "markdown-to-jsx";
import React from "react";
import ReactDOMClient from "react-dom/client";

const runChecks = import.meta.env.DEV;

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
    const { ...i18nrest } = i18noptions;
    const plainLocalized = i18n.t(this.prefix + key, { ...i18nrest, externalLinks });
    if (runChecks) {
      this.checkKeyName(key);
      compileStringAsync(plainLocalized, (localizedAsMd) => {
        if (localizedAsMd && plainLocalized && localizedAsMd === plainLocalized) {
          // The plain localized string is equal to what would have been rendered by markdown;
          // this is NOT a markdown string but we are using a markdown render function.
          // Tell the dev to use 't' instead.
          logger
            .context({ key: key, input: plainLocalized, output: localizedAsMd })
            .error("used i18n.mdx for non-markdown, use i18n.t");
        }
      });
    }
    return <SumaMarkdown options={mdoptions}>{plainLocalized}</SumaMarkdown>;
  };

  md = (key, options = {}) => {
    return this.mdx(key, { forceWrapper: true, wrapper: React.Fragment }, options);
  };

  mdp = (key, options = {}) => {
    return this.mdx(key, { forceBlock: true }, options);
  };

  t = (key, options = {}) => {
    const { ...restopts } = options;
    const localized = i18n.t(this.prefix + key, restopts);
    if (runChecks) {
      this.checkKeyName(key);
      compileStringAsync(localized, (localizedAsMd) => {
        if (localizedAsMd && localized && localizedAsMd !== localized) {
          // We know this should be a markdown string, since we rendered it as markdown
          // and it changed form.
          logger
            .context({ key: key, input: localized, output: localizedAsMd })
            .error("used i18n.t for a markdown string, use a i18n.md variant");
        }
      });
    }
    return localized;
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
    const compiledMdToJsx = compiler(str || "", {
      wrapper: React.Fragment,
      forceWrapper: true,
    });
    const div = document.createElement("div");
    const root = ReactDOMClient.createRoot(div);
    root.render(<div ref={(r) => r && cb(r.innerHTML)}>{compiledMdToJsx}</div>);
  }, 0);
}
