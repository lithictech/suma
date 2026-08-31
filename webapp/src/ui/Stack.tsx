import { DirectionProps, getDirection } from "../types/direction.ts";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface StackProps extends DirectionProps {
  id?: string;
  gap?: number;
  wrap?: boolean;
  center?: boolean;
  children?: React.ReactNode;
  className?: string;
  style?: CSSProperties;
}

const Stack = React.forwardRef<HTMLDivElement, StackProps>(function Stack(
  {
    id,
    gap = 0,
    wrap = false,
    center = false,
    className,
    children,
    style,
    ...rest
  }: StackProps,
  ref
) {
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
    <div ref={ref} id={id} className={cls} style={style}>
      {children}
    </div>
  );
});

export default Stack;

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
