import ELink from "./ELink";
import Markdown from "markdown-to-jsx";
import React from "react";

export default function SumaMarkdown({ options, overrides, children }) {
  overrides = { a: { component: MdLink }, ...overrides };
  options = { overrides, ...options };
  return <Markdown options={options}>{children || ""}</Markdown>;
}

export function MdLink({ node, ...rest }) {
  return <ELink {...rest} />;
}
