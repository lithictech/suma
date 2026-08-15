import React, { CSSProperties } from "react";

export interface IconProps {
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  size?: number | string | "inherit" | null;
  className?: string;
}
export default function Icon({
  icon: IconComponent,
  size = "inherit",
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
  return <IconComponent className={className} style={style} />;
}
