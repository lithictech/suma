import "./Button.css";
import clsx from "clsx";
import React from "react";

const Button = React.forwardRef(function Button(
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
