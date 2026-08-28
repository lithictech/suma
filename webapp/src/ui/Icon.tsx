import ChevronLeftIcon from "@heroicons/react/24/outline/ChevronLeftIcon";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import React, { CSSProperties } from "react";

export type IconPropsIcon =
  | React.ComponentType<React.SVGProps<SVGSVGElement>>
  | "right"
  | "left";

export interface IconProps {
  icon: IconPropsIcon;
  size?: number | string | "inherit" | null;
  className?: string;
}
export default function Icon({
  icon: IconComponent,
  size = "inherit",
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
  return <IconComponent className={className} style={style} />;
}
