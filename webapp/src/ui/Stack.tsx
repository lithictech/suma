import clsx from "clsx";
import React from "react";

interface StackProps {
  direction?: "horizontal" | "vertical";
  gap?: number;
  wrap?: boolean;
  children?: React.ReactNode;
}

export default function Stack({ direction, gap, wrap, children }: StackProps) {
  const cls = clsx(
    `gap-${gap || 0}`,
    `d-flex`,
    FLEX_CLS[direction || "horizontal"],
    wrap && "flex-wrap"
  );
  return <div className={cls}>{children}</div>;
}

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
