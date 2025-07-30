import clsx from "clsx";
import React from "react";

/**
 * Component for rendering the title of a page.
 * @param {Number} level Heading level (1-6). Default 2.
 * @param className
 * @param children
 */
export default function PageHeading({ level, className, children }) {
  const C = `h${level || 2}`;
  return <C className={clsx("page-heading", className)}>{children}</C>;
}
