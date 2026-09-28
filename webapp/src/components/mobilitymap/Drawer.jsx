import clsx from "clsx";
import React from "react";

/**
 * The drawer can take focus from script (it is not in the tab order),
 * for when a vehicle is selected on the map. Pass a ref to get the drawer element.
 */
const Drawer = React.forwardRef(function Drawer(
  { footer, children, className, ...rest },
  ref
) {
  return (
    <div ref={ref} tabIndex={-1} className={clsx("mobility-drawer", className)} {...rest}>
      <div className={clsx("mobility-drawer-main", !footer && "mobility-drawer-footer")}>
        {children}
      </div>
      {footer && <div className="mobility-drawer-footer">{footer}</div>}
    </div>
  );
});

export default Drawer;
