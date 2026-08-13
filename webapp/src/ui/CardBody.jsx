import "./CardBody.css";
import clsx from "clsx";
import React from "react";

export default function CardBody({ className, children }) {
  const cls = clsx("card-body", className);
  return <div className={cls}>{children}</div>;
}
