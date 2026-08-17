import "./ButtonGroup.css";
import { DirectionProps, getDirection } from "./types.tsx";
import clsx from "clsx";
import React from "react";

interface ButtonGroupProps extends DirectionProps {
  className?: string;
  bottom?: boolean;
  children?: React.ReactNode;
}

export default function ButtonGroup({
  className,
  children,
  bottom,
  ...rest
}: ButtonGroupProps) {
  const direction = getDirection(rest);
  const cls = clsx(
    "button-group",
    `button-group-${direction}`,
    bottom && "button-group-bottom",
    className
  );
  return <div className={cls}>{children}</div>;
}
