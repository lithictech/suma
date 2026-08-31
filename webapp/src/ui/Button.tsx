import Link from "../routing/Link.tsx";
import { RoutePathOrUrl } from "../routing/RoutePath.ts";
import "./Button.css";
import clsx from "clsx";
import React, { CSSProperties, MouseEventHandler } from "react";

export interface ButtonProps {
  variant?: "primary" | "secondary" | "text" | "outline";
  size?: "sm" | "md" | "lg";
  className?: string;
  to?: RoutePathOrUrl;
  disabled?: boolean;
  inline?: boolean;
  children?: React.ReactNode;
  style?: CSSProperties;
  title?: string;
  type?: "submit" | "reset" | "button" | undefined;
  value?: string;
  onClick?: MouseEventHandler;
}

const Button = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function Button(
    {
      className,
      to,
      variant = "primary",
      size = "md",
      disabled,
      inline,
      children,
      type = "button",
      ...rest
    },
    ref
  ) {
    const cls = clsx(
      className,
      `btn`,
      `btn-${variant}`,
      `btn-${size}`,
      inline && `btn-inline btn-inline-${size}`,
      to && "btn-link"
    );
    if (to) {
      return (
        <Link
          ref={ref as React.Ref<HTMLAnchorElement>}
          to={to}
          className={cls}
          aria-disabled={disabled}
          {...rest}
        >
          {children}
        </Link>
      );
    }
    return (
      <button
        ref={ref as React.Ref<HTMLButtonElement>}
        type={type}
        disabled={disabled}
        className={cls}
        {...rest}
      >
        {children}
      </button>
    );
  }
);
export default Button;
