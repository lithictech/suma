import { t } from "../localization";
import clsx from "clsx";
import React from "react";

interface FormErrorProps {
  error?: any;
  noMargin?: boolean;
  center?: boolean;
  end?: boolean;
  component?: React.ElementType;
  className?: string;
  style?: React.CSSProperties;
}

const FormError = React.forwardRef<HTMLElement, FormErrorProps>(
  ({ error, noMargin, center, end, component, className, style }, ref) => {
    if (!error) {
      return null;
    }
    const Component = component || "p";
    const msg = React.isValidElement(error) ? error : t("errors." + error);
    const cls = clsx(
      "d-block text-danger small",
      noMargin && "m-0",
      center && "text-center",
      end && "text-end",
      className
    );
    return (
      <Component ref={ref} className={cls} style={style} role="alert">
        {msg}
      </Component>
    );
  }
);

export default FormError;
