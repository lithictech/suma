import "./Form.css";
import clsx from "clsx";
import React from "react";

interface FormProps extends React.FormHTMLAttributes<HTMLFormElement> {
  gap?: number;
  children?: React.ReactNode;
}

export default function Form({ gap = 2, children, className, ...rest }: FormProps) {
  return (
    <form className={clsx("form", `gap-${gap}`, className)} {...rest}>
      {children}
    </form>
  );
}
