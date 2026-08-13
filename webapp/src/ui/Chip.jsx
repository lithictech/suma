import clsx from "clsx";
import React from "react";

export default function Chip({ variant, className, ...rest }) {
  const cls = clsx(className, `chip`, `chip-${variant || "secondary"}`);
  return <div className={cls} {...rest} />;
}
