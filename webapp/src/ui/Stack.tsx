import { DirectionProps, getDirection } from "../types/direction.ts";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface StackProps extends DirectionProps {
  gap?: number;
  wrap?: boolean;
  center?: boolean;
  children?: React.ReactNode;
  className?: string;
  style?: CSSProperties;
}

export default function Stack({
  gap = 0,
  wrap = false,
  center = false,
  className,
  children,
  style,
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
  return (
    <div className={cls} style={style}>
      {children}
    </div>
  );
}

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
