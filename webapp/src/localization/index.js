import ELink from "../components/ELink";
import externalLinks from "../modules/externalLinks";
import i18n from "i18next";
import React from "react";
import ReactMarkdown from "react-markdown";

const runChecks = process.env.NODE_ENV === "development";

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
 */
export function mdx(key, mdoptions = {}, i18noptions = {}) {
  if (runChecks) {
    if (!key.endsWith("_md")) {
      console.error(
        `loc key '${key}' does not end with _md but md() was used (is unnecessarily slow)`
      );
    }
    checkKeyName(key);
  }
  const str = i18n.t("strings:" + key, { ...i18noptions, externalLinks });
  const components = { a: MdLink, ...mdoptions.components };
  return <ReactMarkdown components={components}>{str}</ReactMarkdown>;
}

export function md(key, options = {}) {
  return mdx(key, { components: { p: React.Fragment } }, options);
}

export function mdp(key, options = {}) {
  return mdx(key, {}, options);
}

function MdLink({ node, ...rest }) {
  return <ELink {...rest} />;
}

export function t(key, options = {}) {
  if (runChecks) {
    if (key.endsWith("_md")) {
      console.error(
        `loc key '${key}' ends with _md but t() was used (will not render markdown)`
      );
    }
    checkKeyName(key);
  }
  return i18n.t("strings:" + key, options);
}

function checkKeyName(key) {
  if (key.startsWith("strings:")) {
    console.error(
      "Do not start localization keys with 'strings:', since it may change in the future."
    );
  }
}
