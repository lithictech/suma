import Copyable from "./Copyable";
import ELink from "./ELink";
import Markdown from "markdown-to-jsx";
import React from "react";

export default function SumaMarkdown({ options, overrides, children }) {
  overrides = {
    a: { component: MdLink },
    Copyable: { component: Copyable, props: { inline: true } },
    ...overrides,
  };
  options = { overrides, ...options };
  return <Markdown options={options}>{children || ""}</Markdown>;
}

// Ignore 'node' because we replace it with ELink
// eslint-disable-next-line no-unused-vars
export function MdLink({ node, ...rest }) {
  return <ELink {...rest} />;
}
