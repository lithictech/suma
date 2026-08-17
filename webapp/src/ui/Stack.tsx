import { DirectionProps, getDirection } from "./types.tsx";
import clsx from "clsx";
import React from "react";

interface StackProps extends DirectionProps {
  gap?: number;
  wrap?: boolean;
  center?: boolean;
  children?: React.ReactNode;
  className?: string;
}

export default function Stack({
  gap = 0,
  wrap = false,
  center = false,
  className,
  children,
  ...rest
}: StackProps) {
  const direction = getDirection(rest);
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
