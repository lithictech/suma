import { ThemeColor } from "../types/theme";
import ChevronLeftIcon from "@heroicons/react/24/outline/ChevronLeftIcon";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import clsx from "clsx";
import React, { CSSProperties } from "react";

export type IconPropsIcon =
  | React.ComponentType<React.SVGProps<SVGSVGElement>>
  | "right"
  | "left";

export interface IconProps {
  icon: IconPropsIcon;
  size?: number | string | "inherit" | null;
  /**
   * If given, wrap the icon in a div which also has an explicit size.
   * Since the icon is an SVG, simply setting size may not result
   * in the desired size.
   */
  forceSize?: boolean;
  className?: string;
  color?: ThemeColor;
}
export default function Icon({
  icon: IconComponent,
  size = "inherit",
  forceSize,
  color,
  className,
}: IconProps) {
  if (IconComponent === "left") {
    IconComponent = ChevronLeftIcon;
  } else if (IconComponent === "right") {
    IconComponent = ChevronRightIcon;
  }
  const style: CSSProperties = {};
  if (size === "inherit") {
    style.width = "1em";
    style.height = "1em";
  } else if (size) {
    style.width = size;
    style.height = size;
  }
  const cls = clsx(color ? `color-${color}` : "", className);
  const el = <IconComponent className={cls} style={style} />;
  if (forceSize) {
    return <div style={style}>{el}</div>;
  }
  return el;
}
