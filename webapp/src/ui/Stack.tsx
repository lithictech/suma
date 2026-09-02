import { DirectionProps, getDirection } from "../types/direction.ts";
import clsx from "clsx";
import React, { CSSProperties } from "react";

export type FlexAlign = "start" | "center" | "end";
export type FlexJustify = "around" | "between" | "evenly" | "start" | "end" | "center";

export interface StackProps extends DirectionProps {
  id?: string;
  gap?: number;
  wrap?: boolean;
  /** Shorthand for align=center or className=align-items-center. */
  center?: boolean;
  align?: FlexAlign;
  justify?: FlexJustify;
  children?: React.ReactNode;
  className?: string;
  style?: CSSProperties;
}

const alignRemaps: Record<FlexAlign, string> = {
  center: "center",
  start: "flex-start",
  end: "flex-end",
};

const justifyRemaps: Record<FlexJustify, string> = {
  start: "flex-start",
  end: "flex-end",
  around: "space-around",
  between: "space-between",
  evenly: "space-evenly",
  center: "center",
};

const Stack = React.forwardRef<HTMLDivElement, StackProps>(function Stack(
  {
    id,
    gap = 0,
    wrap = false,
    center = false,
    align,
    justify,
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
  const sty = { ...style };
  if (align) {
    sty.alignItems = alignRemaps[align];
  }
  if (justify) {
    sty.justifyContent = justifyRemaps[justify];
  }
  return (
    <div ref={ref} id={id} className={cls} style={sty}>
      {children}
    </div>
  );
});

export default Stack;

const FLEX_CLS = { horizontal: "flex-row", vertical: "flex-column" };
