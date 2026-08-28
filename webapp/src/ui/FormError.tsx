import { t } from "../localization";
import "./FormError.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

export type FormErrorError = null | undefined | string | React.ReactNode;

interface FormErrorProps {
  error: FormErrorError;
  noSurface?: boolean;
  className?: string;
  style?: CSSProperties;
}

const FormError = React.forwardRef<HTMLElement, FormErrorProps>(
  ({ error, noSurface, style, className }, ref) => {
    if (!error) {
      return null;
    }
    const msg = React.isValidElement(error) ? error : t("errors." + error);
    const cls = clsx("form-error", !noSurface && "form-error-surface", className);
    return (
      <p
        ref={ref as React.ForwardedRef<HTMLParagraphElement>}
        className={cls}
        style={style}
        role="alert"
      >
        {msg}
      </p>
    );
  }
);

export default FormError;
