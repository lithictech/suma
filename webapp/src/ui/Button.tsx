import "./Button.css";
import clsx from "clsx";
import React from "react";
import { Link, LinkProps } from "react-router-dom";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "text" | "outline";
  size?: "sm" | "md" | "lg";
  className?: string;
  href?: string;
  to?: LinkProps["to"];
  disabled?: boolean;
  children?: React.ReactNode;
  state?: ShimProps;
}

const Button = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function Button(
    {
      className,
      to,
      href,
      variant = "primary",
      size = "md",
      disabled,
      children,
      ...rest
    },
    ref
  ) {
    to = to || href;
    const cls = clsx(
      className,
      `btn`,
      `btn-${variant || "primary"}`,
      `btn-${size || "md"}`,
      to && "btn-link"
    );
    if (to) {
      return (
        <Link
          ref={ref as React.Ref<HTMLAnchorElement>}
          to={to}
          className={cls}
          aria-disabled={disabled}
        >
          {children}
        </Link>
      );
    }
    return (
      <button
        ref={ref as React.Ref<HTMLButtonElement>}
        type="button"
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
