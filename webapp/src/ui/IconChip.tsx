import { TintColor } from "../types/theme";
import Icon, { IconProps } from "./Icon.tsx";
import "./IconChip.css";

export interface IconChipProps extends IconProps {
  color: TintColor;
  size: number;
}

export default function IconChip({ color, size, ...rest }: IconChipProps) {
  return (
    <div
      className={`icon-chip bgcolor-tint-${color}`}
      style={{ width: size, height: size }}
    >
      <Icon size={size * 0.5} {...rest} />
    </div>
  );
}
