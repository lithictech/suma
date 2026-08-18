import Link from "../routing/Link.tsx";
import { RoutePath } from "../routing/RoutePath.ts";
import "./NavOption.css";
import clsx from "clsx";
import React from "react";

interface NavOptionProps {
  size?: number;
  label?: React.ReactNode;
  Icon: React.ComponentType<{ className?: string; style?: React.CSSProperties }>;
  active?: boolean;
  to: RoutePath;
}

export default function NavOption({
  size = 24,
  label,
  Icon,
  active,
  to,
}: NavOptionProps) {
  return (
    <Link to={to} className="nav-option-anchor">
      <div className="nav-option">
        <div className={clsx("nav-option-icon", active && "active")}>
          <Icon className="nav-option-icon-svg" style={{ width: size, height: size }} />
        </div>
        <div className={clsx("nav-option-label", active && "active")}>{label}</div>
      </div>
    </Link>
  );
}
