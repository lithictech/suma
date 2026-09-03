import { ThemeColor } from "../types/theme";
import IndeterminateLoader from "./IndeterminateLoader.tsx";
import ChevronLeftIcon from "@heroicons/react/24/outline/ChevronLeftIcon";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import clsx from "clsx";
import React, { CSSProperties } from "react";

export type IconPropsIcon =
  | React.ComponentType<React.SVGProps<SVGSVGElement>>
  | "right"
  | "left"
  | "loader";

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
  const style: CSSProperties = {};
  if (size === "inherit") {
    style.width = "1em";
    style.height = "1em";
  } else if (size) {
    style.width = size;
    style.height = size;
  }
  const elProps = { className: clsx(color ? `color-${color}` : "", className), style };

  let el: React.ReactElement;
  if (IconComponent === "left") {
    el = <ChevronLeftIcon {...elProps} />;
  } else if (IconComponent === "right") {
    el = <ChevronRightIcon {...elProps} />;
  } else if (IconComponent === "loader") {
    el = <IndeterminateLoader variant="plain" size={size || "inherit"} {...elProps} />;
  } else {
    el = <IconComponent {...elProps} />;
  }
  if (forceSize) {
    return <div style={style}>{el}</div>;
  }
  return el;
}
