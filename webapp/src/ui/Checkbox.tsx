import useId from "../state/useId";
import "./Checkbox.css";
import InputFeedback, { HasInputFeedback } from "./InputFeedback.tsx";
import clsx from "clsx";
import React from "react";

export interface CheckboxProps
  extends HasInputFeedback,
    Omit<React.InputHTMLAttributes<HTMLInputElement>, "checked" | "type"> {
  label?: React.ReactNode;
  checked: boolean;
  inputClass?: string;
}

const Checkbox = React.forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { label, checked, error, help, required = false, id, className, inputClass, ...rest },
  ref
) {
  const inputId = useId(id);
  return (
    <div className={className}>
      <label className="form-check">
        <input
          ref={ref}
          id={inputId}
          type="checkbox"
          checked={checked}
          required={required}
          className={clsx(error && "is-invalid", inputClass)}
          aria-describedby={InputFeedback.idFor(inputId)}
          aria-invalid={error ? true : undefined}
          {...rest}
        />
        <span>
          {label}
          {required && <span className="ml-1 color-danger">*</span>}
        </span>
      </label>
      <InputFeedback inputId={inputId} error={error} help={help} />
    </div>
  );
});
export default Checkbox;
