import "./CardText.css";
import clsx from "clsx";
import React from "react";

interface CardTextProps {
  variant?: "title" | "subtitle" | "text" | "subtext";
  className?: string;
  children?: React.ReactNode;
}

export default function CardText({
  variant = "text",
  className,
  children,
}: CardTextProps) {
  const cls = clsx(className, "card-text", `card-text-${variant}`);
  return <div className={cls}>{children}</div>;
}
