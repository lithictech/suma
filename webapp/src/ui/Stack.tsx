import clsx from "clsx";
import React from "react";

interface StackProps {
  direction?: "horizontal" | "vertical";
  gap?: number;
  wrap?: boolean;
  children?: React.ReactNode;
  className?: string;
}

export default function Stack({ direction, gap, wrap, className, children }: StackProps) {
  const cls = clsx(
    `gap-${gap || 0}`,
    `d-flex`,
    FLEX_CLS[direction || "horizontal"],
    wrap && "flex-wrap",
    className
  );
  return <div className={cls}>{children}</div>;
}

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
