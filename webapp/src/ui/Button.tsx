import Link from "../routing/Link.tsx";
import { RoutePathOrUrl } from "../routing/RoutePath.ts";
import "./Button.css";
import clsx from "clsx";
import React, { CSSProperties, MouseEventHandler } from "react";

export type ButtonVariant = "filled" | "text" | "outline";
export type ButtonColor = "primary" | "secondary" | "danger" | "success";
export type ButtonPreset = "primary" | "secondary";
export type ButtonSize = "sm" | "md" | "lg";
interface ButtonStyle extends CSSProperties {
  "--btn-color"?: string;
  "--btn-color-hover"?: string;
  "--btn-bg"?: string;
  "--btn-bg-hover"?: string;
}

export interface ButtonProps {
  variant?: ButtonVariant;
  color?: ButtonColor;
  size?: ButtonSize;
  preset?: ButtonPreset;
  className?: string;
  style?: ButtonStyle;
  to?: RoutePathOrUrl;
  disabled?: boolean;
  inline?: boolean;
  children?: React.ReactNode;
  title?: string;
  type?: "submit" | "reset" | "button" | undefined;
  value?: string;
  onClick?: MouseEventHandler;
}

const Button = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function Button(
    {
      className,
      style,
      to,
      variant = "filled",
      color = "primary",
      size = "md",
      preset,
      disabled,
      inline,
      children,
      type = "button",
      ...rest
    },
    ref
  ) {
    if (preset === "primary") {
      color = "primary";
      variant = "filled";
    } else if (preset === "secondary") {
      color = "secondary";
      variant = "filled";
    }
    const cls = clsx(
      className,
      `btn`,
      `btn-${variant}`,
      `btn-${size}`,
      inline && `btn-inline btn-inline-${size}`,
      to && "btn-link"
    );
    const sty: ButtonStyle = { ...toColorStyle(variant, color), ...style };
    if (to) {
      return (
        <Link
          ref={ref as React.Ref<HTMLAnchorElement>}
          to={to}
          className={cls}
          style={sty}
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
        style={sty}
        {...rest}
      >
        {children}
      </button>
    );
  }
);

export default Button;

function toColorStyle(v: ButtonVariant, c: ButtonColor): ButtonStyle {
  const transparentBg = v === "outline" || v === "text";
  if (transparentBg) {
    return {
      "--btn-color": `var(--color-${c})`,
      "--btn-color-hover": `var(--color-${c}-hover)`,
      "--btn-bg": `transparent`,
      "--btn-bg-hover": `transparent`,
    };
  }
  const contrastBased = c === "primary" || c === "secondary";
  if (contrastBased) {
    return {
      "--btn-color": `var(--color-${c}-contrast)`,
      "--btn-color-hover": `var(--color-${c}-contrast)`,
      "--btn-bg": `var(--color-${c})`,
      "--btn-bg-hover": `var(--color-${c}-hover)`,
    };
  }
  return {
    "--btn-color": `var(--color-primary-contrast)`,
    "--btn-color-hover": `var(--color-primary-contrast)`,
    "--btn-bg": `var(--color-${c})`,
    "--btn-bg-hover": `var(--color-${c}-hover)`,
  };
}
