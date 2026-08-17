import { t } from "../localization";
import "./FormError.css";
import clsx from "clsx";
import React from "react";

interface FormErrorProps {
  error?: any;
  className?: string;
  [rest: string]: ShimProps;
}

const FormError = React.forwardRef<HTMLElement, FormErrorProps>(
  ({ error, className }, ref) => {
    if (!error) {
      return null;
    }
    const msg = React.isValidElement(error) ? error : t("errors." + error);
    const cls = clsx("form-error", className);
    return (
      <p
        ref={ref as React.ForwardedRef<HTMLParagraphElement>}
        className={cls}
        role="alert"
      >
        {msg}
      </p>
    );
  }
);

export default FormError;
