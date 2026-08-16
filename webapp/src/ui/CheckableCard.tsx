import useId from "../state/useId.ts";
import "./CheckableCard.css";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import clsx from "clsx";
import React from "react";

export interface CheckableCardProps
  extends HasFormFeedback,
    React.InputHTMLAttributes<HTMLInputElement> {
  checked: boolean;
  name?: string;
  disabled?: boolean;
  className?: string;
  style?: React.CSSProperties;
  children?: React.ReactNode;
}

const CheckableCard = React.forwardRef<HTMLInputElement, CheckableCardProps>(
  function CheckableCard(
    {
      id,
      checked,
      name,
      disabled = false,
      className,
      style,
      help,
      error,
      children,
      ...rest
    }: CheckableCardProps,
    ref
  ) {
    const inputId = useId(id);
    const cls = clsx("card checkable-card checkable-card-hidecheck", className);
    return (
      <div>
        <label className={cls} style={style}>
          <input
            ref={ref}
            type="checkbox"
            name={name}
            checked={checked}
            disabled={disabled}
            {...rest}
          />
          {children}
        </label>
        <FormFeedback inputId={inputId} error={error} help={help} />
      </div>
    );
  }
);
export default CheckableCard;
