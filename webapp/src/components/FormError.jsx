import { t } from "../localization";
import setRef from "../shared/setRef";
import clsx from "clsx";
import React from "react";

const FormError = React.forwardRef(
  ({ error, noMargin, center, end, component, className, style, ...rest }, ref) => {
    const innerRef = React.useRef(null);
    const mountedRef = React.useRef(false);
    React.useEffect(() => {
      // When an error appears after the page has loaded (usually after submitting),
      // bring it into view, since it is often below where the user is looking
      // and easy to miss. It is already announced through role="alert".
      // Skip the first render so an error present on load does not scroll the page.
      if (mountedRef.current && error) {
        innerRef.current?.scrollIntoView?.({ block: "nearest" });
      }
      mountedRef.current = true;
    }, [error]);
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
      <Component
        ref={(r) => {
          innerRef.current = r;
          setRef(ref, r);
        }}
        className={cls}
        style={style}
        role="alert"
        {...rest}
      >
        {msg}
      </Component>
    );
  }
);

export default FormError;
