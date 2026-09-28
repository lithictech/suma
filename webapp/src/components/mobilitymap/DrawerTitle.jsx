import clsx from "clsx";
import React from "react";

/**
 * Title of the drawer. It can take focus from script (it is not in the tab order),
 * so focus can move here when the drawer opens.
 */
export default function DrawerTitle({ className, ...rest }) {
  return (
    <h5
      tabIndex={-1}
      className={clsx(className, "mobility-drawer-title", "mb-0")}
      {...rest}
    />
  );
}
