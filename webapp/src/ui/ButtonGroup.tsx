import "./ButtonGroup.css";
import clsx from "clsx";
import React from "react";

interface ButtonGroupProps {
  className?: string;
  vertical?: ShimProps;
  children?: React.ReactNode;
}

export default function ButtonGroup({ className, children }: ButtonGroupProps) {
  const cls = clsx("button-group", className);
  return <div className={cls}>{children}</div>;
}
