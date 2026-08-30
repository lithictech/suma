import { t } from "../localization";
import { OptionalError } from "../state/useError.tsx";
import "./FormError.css";
import clsx from "clsx";
import React, { CSSProperties } from "react";

interface FormErrorProps {
  error: OptionalError;
  noSurface?: boolean;
  className?: string;
  style?: CSSProperties;
  variant?: "danger" | "success";
}

const FormError = React.forwardRef<HTMLElement, FormErrorProps>(
  ({ error, noSurface, style, className, variant = "danger" }, ref) => {
    if (!error) {
      return null;
    }
    const sty = { ...style, color: `var(--color-${variant})` };
    if (!noSurface) {
      sty.backgroundColor = `var(--tint-${variant})`;
    }

    const msg = React.isValidElement(error) ? error : t("errors." + error);
    const cls = clsx("form-error", !noSurface && "form-error-surface", className);
    return (
      <p
        ref={ref as React.ForwardedRef<HTMLParagraphElement>}
        className={cls}
        style={sty}
        role="alert"
      >
        {msg}
      </p>
    );
  }
);

export default FormError;
