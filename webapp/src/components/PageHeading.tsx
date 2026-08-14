import clsx from "clsx";
import React from "react";

interface PageHeadingProps {
  /** Heading level (1-6). Default 2. */
  level?: number;
  className?: string;
  children?: React.ReactNode;
}

/**
 * Component for rendering the title of a page.
 */
export default function PageHeading({ level, className, children }: PageHeadingProps) {
  const C = `h${level || 2}` as React.ElementType;
  return <C className={clsx("page-heading", className)}>{children}</C>;
}
