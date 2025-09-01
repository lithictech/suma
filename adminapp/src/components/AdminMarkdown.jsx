import Link from "./Link";
import Markdown from "markdown-to-jsx";
import React from "react";

export default function AdminMarkdown({ options, overrides, children }) {
  overrides = {
    a: { component: MdLink },
    ...overrides,
  };
  options = { overrides, ...options };
  return <Markdown options={options}>{children || ""}</Markdown>;
}

// Ignore 'node' because we replace it with Link
// eslint-disable-next-line no-unused-vars
function MdLink({ node, ...rest }) {
  return <Link {...rest} />;
}
