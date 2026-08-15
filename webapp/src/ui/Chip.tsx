import "./Chip.css";
import clsx from "clsx";
import React from "react";

interface ChipProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "info" | "secondary" | "success" | "danger";
}

export default function Chip({ variant = "secondary", className, ...rest }: ChipProps) {
  const cls = clsx(className, `chip`, `chip-${variant}`);
  return <div className={cls} {...rest} />;
}
