import clsx from "clsx";
import React from "react";

interface StackProps {
  direction?: "horizontal" | "vertical";
  gap?: number;
  wrap?: boolean;
  center?: boolean;
  vertical?: boolean;
  col?: boolean;
  column?: boolean;
  horizontal?: boolean;
  row?: boolean;
  children?: React.ReactNode;
  className?: string;
}

export default function Stack({
  direction = "horizontal",
  gap = 0,
  wrap = false,
  center = false,
  vertical = false,
  col = false,
  column = false,
  horizontal = false,
  row = false,
  className,
  children,
}: StackProps) {
  if (vertical || col || column) {
    direction = "vertical";
  } else if (horizontal || row) {
    direction = "horizontal";
  }
  const cls = clsx(
    `gap-${gap}`,
    `d-flex`,
    FLEX_CLS[direction],
    wrap && "flex-wrap",
    center && "align-items-center",
    className
  );
  return <div className={cls}>{children}</div>;
}

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
