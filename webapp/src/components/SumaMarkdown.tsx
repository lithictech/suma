import Copyable from "../ui/Copyable";
import ELink from "./ELink";
import Markdown from "markdown-to-jsx";
import React from "react";

interface SumaMarkdownProps {
  /** Passed to Markdown, with exceptions listed here.
   * `overrides` is merged on top of the default overrides,
   * which include a Copyable component and custom link. */
  options?: { overrides?: Record<string, any>; [rest: string]: any };
  children?: React.ReactNode;
}

/**
 * Render Markdown with Suma components and options.
 */
export default function SumaMarkdown({ options, children }: SumaMarkdownProps) {
  const { overrides, ...rest } = options || {};
  const combinedOverrides = {
    a: { component: MdLink },
    Copyable: { component: Copyable, props: { inline: true } },
    ...overrides,
  };
  const mdopts = { overrides: combinedOverrides, ...rest };
  return <Markdown options={mdopts}>{(children as string) || ""}</Markdown>;
}

// Ignore 'node' because we replace it with ELink
// eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
export function MdLink({ node, ...rest }: { node?: any; [rest: string]: any }) {
  return <ELink {...rest} />;
}
