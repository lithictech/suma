import clsx from "clsx";
import React from "react";

/**
 * react-bootstrap uses 'small' for form text rather than div.
 * This is not standard (pretty sure it' sa bug), and prohibits top margin.
 */
export default function FormText({ className, muted, ...rest }) {
  const cls = clsx("form-text", muted && "text-muted", className);
  return <div className={cls} {...rest} />;
}
