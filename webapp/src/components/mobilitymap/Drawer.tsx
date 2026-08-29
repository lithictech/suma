import clsx from "clsx";
import React from "react";

interface DrawerProps {
  children?: React.ReactNode;
  noPosition?: boolean;
  className?: string;
}

export default function Drawer({ children, noPosition = false, className }: DrawerProps) {
  return (
    <div
      className={clsx(
        "mobility-drawer",
        !noPosition && "mobility-drawer-position",
        className
      )}
    >
      {children}
    </div>
  );
}
