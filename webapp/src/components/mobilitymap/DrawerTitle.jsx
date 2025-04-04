import clsx from "clsx";
import React from "react";

export default function DrawerTitle({ className, ...rest }) {
  return <h5 className={clsx("mb-2", className)} {...rest} />;
}
