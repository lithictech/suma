import "./CardText.css";
import clsx from "clsx";
import React from "react";

export default function CardText({ variant, className, children }) {
  const cls = clsx(className, "card-text", `card-text-${variant || "base"}`);
  return <div className={cls}>{children}</div>;
}
