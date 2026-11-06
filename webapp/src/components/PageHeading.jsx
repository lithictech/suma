import clsx from "clsx";
import React from "react";

/**
 * Component for rendering the title of a page.
 * @param {Number} level Heading level (1-6). Default 1.
 * @param className
 * @param children
 */
export default function PageHeading({ level, className, children }) {
  const C = `h${level || 1}`;
  // Page titles default to h1 for document structure, but keep the size they
  // had as h2 so the change of level is not a visual change.
  return <C className={clsx("page-heading", !level && "h2", className)}>{children}</C>;
}
