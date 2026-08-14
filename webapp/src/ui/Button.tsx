import "./Button.css";
import clsx from "clsx";
import React from "react";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: string;
  size?: string;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant, size, className, ...rest },
  ref
) {
  const cls = clsx(
    className,
    `btn`,
    `btn-${variant || "primary"}`,
    `btn-${size || "md"}`
  );
  return <button ref={ref} type="button" className={cls} {...rest} />;
});
export default Button;
