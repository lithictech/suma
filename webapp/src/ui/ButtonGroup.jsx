import "./ButtonGroup.css";
import clsx from "clsx";
import React from "react";

export default function ButtonGroup({ className, children }) {
  const cls = clsx("button-group", className);
  return <div className={cls}>{children}</div>;
}
