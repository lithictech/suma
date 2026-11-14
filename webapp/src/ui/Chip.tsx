import { ThemeColor } from "../types/theme";
import "./Chip.css";
import clsx from "clsx";
import React from "react";

interface ChipProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: ThemeColor;
  invert?: boolean;
  bullet?: boolean;
}

export default function Chip({
  variant = "primary",
  invert,
  bullet,
  className,
  ...rest
}: ChipProps) {
  if (bullet) {
    return <div className={clsx("chip-bullet", `bgcolor-${variant}`)}>&nbsp;</div>;
  }
  const cls = clsx(
    className,
    `chip`,
    `chip-${variant}`,
    invert
      ? `color-${variant}-contrast bgcolor-${variant}`
      : `color-${variant} bgcolor-${variant}-soft`
  );
  return <div className={cls} {...rest} />;
}
