import "./Button.css";
import clsx from "clsx";
import React from "react";
import { Link, LinkProps } from "react-router-dom";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "text" | "outline";
  size?: "sm" | "md" | "lg";
  className?: string;
  href?: string;
  to?: LinkProps["to"];
  children?: React.ReactNode;
  state?: ShimProps;
}

const Button = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function Button(
    { className, to, href, variant = "primary", size = "md", children, ...rest },
    ref
  ) {
    const cls = clsx(
      className,
      `btn`,
      `btn-${variant || "primary"}`,
      `btn-${size || "md"}`
    );
    to = to || href;
    if (to) {
      return <Link ref={ref as React.Ref<HTMLAnchorElement>} to={to}></Link>;
    }
    return (
      <button
        ref={ref as React.Ref<HTMLButtonElement>}
        type="button"
        className={cls}
        {...rest}
      >
        {children}
      </button>
    );
  }
);
export default Button;
