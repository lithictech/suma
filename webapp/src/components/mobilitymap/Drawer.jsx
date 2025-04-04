import clsx from "clsx";
import React from "react";

export default function Drawer({ children, className }) {
  return <div className={clsx("mobility-drawer", className)}>{children}</div>;
}
