import clsx from "clsx";
import React from "react";

export default function Stack({ direction, gap, children }) {
  const cls = clsx(`gap-${gap || 0}`, `d-flex`, FLEX_CLS[direction || "horizontal"]);
  return <div className={cls}>{children}</div>;
}

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
