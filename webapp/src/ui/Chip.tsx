import "./Chip.css";
import clsx from "clsx";
import React from "react";

interface ChipProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: string;
}

export default function Chip({ variant, className, ...rest }: ChipProps) {
  const cls = clsx(className, `chip`, `chip-${variant || "secondary"}`);
  return <div className={cls} {...rest} />;
}
