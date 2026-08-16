import useId from "../state/useId";
import "./Checkbox.css";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import clsx from "clsx";
import React from "react";

export interface CheckboxProps
  extends HasFormFeedback,
    Omit<React.InputHTMLAttributes<HTMLInputElement>, "checked" | "type"> {
  label?: React.ReactNode;
  checked: boolean;
}

const Checkbox = React.forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox(
  { label, checked, error, help, required = false, id, className, ...rest },
  ref
) {
  const inputId = useId(id);
  return (
    <div>
      <label className="form-check">
        <input
          ref={ref}
          id={inputId}
          type="checkbox"
          checked={checked}
          required={required}
          className={clsx(className, error && "is-invalid")}
          aria-describedby={FormFeedback.idFor(inputId)}
          aria-invalid={error ? true : undefined}
          {...rest}
        />
        <span>
          {label}
          {required && <span className="ml-1 color-danger">*</span>}
        </span>
      </label>
      <FormFeedback inputId={inputId} error={error} help={help} />
    </div>
  );
});
export default Checkbox;
