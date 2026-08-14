import "./CardText.css";
import clsx from "clsx";
import React from "react";

interface CardTextProps {
  variant?: string;
  className?: string;
  children?: React.ReactNode;
}

export default function CardText({ variant, className, children }: CardTextProps) {
  const cls = clsx(className, "card-text", `card-text-${variant || "text"}`);
  return <div className={cls}>{children}</div>;
}
