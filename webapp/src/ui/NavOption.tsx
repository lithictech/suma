import "./NavOption.css";
import clsx from "clsx";
import React from "react";

interface NavOptionProps {
  size?: number;
  label?: React.ReactNode;
  Icon: React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
  active?: boolean;
}

export default function NavOption({ size = 24, label, Icon, active }: NavOptionProps) {
  return (
    <div className="nav-option">
      <div className={clsx("nav-option-icon", active && "active")}>
        <Icon className="nav-option-icon-svg" style={{ width: size, height: size }} />
      </div>
      <div className={clsx("nav-option-label", active && "active")}>{label}</div>
    </div>
  );
}
