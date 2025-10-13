import Copyable from "./Copyable";
import ELink from "./ELink";
import Markdown from "markdown-to-jsx";
import React from "react";

/**
 * Render Markdown with Suma components and options.
 * @param {object} options Passed to Markdown, with exceptions listed here.
 * @param {object} options.overrides Merged on top of the default overrides,
 *   which include a Copyable component and custom link.
 * @param children
 */
export default function SumaMarkdown({ options, children }) {
  const { overrides, ...rest } = options || {};
  const combinedOverrides = {
    a: { component: MdLink },
    Copyable: { component: Copyable, props: { inline: true } },
    ...overrides,
  };
  const mdopts = { overrides: combinedOverrides, ...rest };
  return <Markdown options={mdopts}>{children || ""}</Markdown>;
}

// Ignore 'node' because we replace it with ELink
// eslint-disable-next-line no-unused-vars
export function MdLink({ node, ...rest }) {
  return <ELink {...rest} />;
}
