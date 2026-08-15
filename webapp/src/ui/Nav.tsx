import "./Nav.css";
import clsx from "clsx";
import React from "react";

export interface NavProps {
  children?: React.ReactNode;
  className?: string;
}

export default function Nav({ className, children }: NavProps) {
  const cls = clsx("nav", className);
  return <div className={cls}>{children}</div>;
}
