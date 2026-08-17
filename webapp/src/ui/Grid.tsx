import clsx from "clsx";
import isNumber from "lodash/isNumber";
import React, { CSSProperties } from "react";

interface GridProps {
  columns: number | string;
  className?: string;
  style?: CSSProperties;
  gap?: number;
  children?: React.ReactNode;
}

export default function Grid({
  columns,
  className,
  style,
  gap = 2,
  children,
}: GridProps) {
  const cls = clsx(`gap-${gap}`, className);
  const sty: CSSProperties = {
    display: "grid",
  };
  if (isNumber(columns)) {
    sty.gridTemplateColumns = `repeat(${columns}, 1fr)`;
  } else {
    sty.gridTemplateColumns = `repeat(auto-fit, minmax(${columns}, 1fr))`;
  }
  return (
    <div className={cls} style={{ ...sty, ...style }}>
      {children}
    </div>
  );
}
