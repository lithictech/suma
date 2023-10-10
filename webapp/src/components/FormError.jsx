import { t } from "../localization";
import clsx from "clsx";
import React from "react";

const FormError = React.forwardRef(
  ({ error, noMargin, center, end, component, className, style }, ref) => {
    if (!error) {
      return null;
    }
    const Component = component || "p";
    const msg = React.isValidElement(error) ? error : t("errors:" + error);
    const cls = clsx(
      "d-block text-danger small",
      noMargin && "m-0",
      center && "text-center",
      end && "text-end",
      className
    );
    return (
      <Component ref={ref} className={cls} style={style}>
        {msg}
      </Component>
    );
  }
);

export default FormError;
