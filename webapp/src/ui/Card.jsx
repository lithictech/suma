import "./Card.css";
import clsx from "clsx";
import React from "react";

export default function Card({ className, children }) {
  const cls = clsx(className, "card");
  return <div className={cls}>{children}</div>;
}
