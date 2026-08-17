import "./CardText.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface CardTextProps {
  variant?: "title" | "subtitle" | "text" | "subtext";
  className?: string;
  style?: CSSProperties;
  children?: React.ReactNode;
}

export default function CardText({
  variant = "text",
  className,
  style,
  children,
}: CardTextProps) {
  const cls = clsx(className, "card-text", `card-text-${variant}`);
  return (
    <div className={cls} style={style}>
      {children}
    </div>
  );
}
