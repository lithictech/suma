import clsx from "clsx";
import React from "react";

export default function Drawer({ footer, children, className }) {
  return (
    <div className={clsx("mobility-drawer", className)}>
      <div className={clsx("mobility-drawer-main", !footer && "mobility-drawer-footer")}>
        {children}
      </div>
      {footer && <div className="mobility-drawer-footer">{footer}</div>}
    </div>
  );
}
