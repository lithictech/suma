import clsx from "clsx";
import React from "react";

interface DrawerProps {
  footer?: React.ReactNode;
  children?: React.ReactNode;
  className?: string;
}

export default function Drawer({ footer, children, className }: DrawerProps) {
  return (
    <div className={clsx("mobility-drawer", className)}>
      {children}
      {footer && <div className="mobility-drawer-footer">{footer}</div>}
    </div>
  );
}
