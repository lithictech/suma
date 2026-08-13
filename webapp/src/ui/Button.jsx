import clsx from "clsx";
import React from "react";

export default function Button({ variant, size, className, ...rest }) {
  const cls = clsx(
    className,
    `btn`,
    `btn-${variant || "primary"}`,
    `btn-${size || "md"}`
  );
  return <button className={cls} {...rest} />;
}
