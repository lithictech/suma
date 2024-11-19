import SumaMarkdown from "../components/SumaMarkdown";
import externalLinks from "../modules/externalLinks";
import { Logger } from "../shared/logger";
import i18n from "./i18n";
import { capitalize } from "lodash";
import React from "react";

const runChecks = import.meta.env.DEV;

const logger = new Logger("i18n");

export class Lookup {
  constructor(prefix) {
    this.prefix = prefix + ".";
  }
  /**
   * Render localization strings.
   *
   * If the localized string is 'plain', it'll be returned verbatim, after interpolation as per i18n.t.
   * If it's markdown, there are two possible behaviors:
   *
   * **If the markdown has no newlines,** then the string will be rendered and returned.
   * For example, if the template was "hello **there**",
   * the rendered markdown will be "hello <strong>there</strong>".
   *
   * However, **if the markdown has newlines**,
   * it'll render paragraphs for each newline.
   * For example, if the template was "hello\n\nthere",
   * the rendered markdown will be "<p>hello</p><p>there</p>".
   *
   * Note: Links are rendered with the ELink component,
   * which will 1) use a new tab for external links,
   * 2) use Link for internal links (# or /),
   * and 3) use a Link with 'replace' if the href includes ##.
   * So ## can be used, for example, to trigger modals controlled by the hash.
   */
  t = (key, i18noptions = {}, { markdown } = {}) => {
    if (runChecks) {
      this.checkKeyName(key);
    }
    const [formatter, localized] = i18n.resolve(this.prefix + key, {
      ...i18noptions,
      externalLinks,
    });
    if (formatter === "s") {
      return localized;
    }
    const mdopts = { ...markdown };
    if (formatter === "m") {
      mdopts.forceWrapper = true;
      mdopts.wrapper = React.Fragment;
    } else {
      mdopts.forceBlock = true;
    }
    return <SumaMarkdown options={mdopts}>{localized}</SumaMarkdown>;
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

/**
 * Applies image alt 'best practices' to localization strings like
 * punctuation and capitalization, then returns it.
 * @param altKey the key to find the localized string
 * @param i18noptions
 * @returns {string} i18n localized alt string
 */
export function imageAltT(altKey, i18noptions = {}) {
  let altStr = t("alts." + altKey, i18noptions);
  const lastChar = altStr[altStr.length - 1];
  if (lastChar !== ".") {
    altStr += ".";
  }
  return capitalize(altStr);
}

/**
 * Render the dynamic translated string.
 * Use the formatter specified by the flag at the start of the string.
 * See Suma::I18n::ResourceRewriter for more info.
 * @param {string} s
 * @return {string|JSX.Element}
 */
export function dt(s) {
  if (!s) {
    return s;
  }
  const flag = s[0];
  if (flag === "\u200C") {
    return (
      <SumaMarkdown options={{ forceWrapper: true, wrapper: React.Fragment }}>
        {s.slice(1)}
      </SumaMarkdown>
    );
  } else if (flag === "\u200D") {
    return <SumaMarkdown options={{ forceBlock: true }}>{s.slice(1)}</SumaMarkdown>;
  }
  return s;
}
