import useId from "../state/useId.ts";
import "./Switch.css";
import React from "react";

export interface SwitchProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: React.ReactNode;
  checked: boolean;
  error?: React.ReactNode;
  name?: string;
  disabled?: boolean;
}

const Switch = React.forwardRef<HTMLInputElement, SwitchProps>(function Switch(
  { id, label, checked, error, name, disabled = false, ...rest }: SwitchProps,
  ref
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const errorId = error ? `${inputId}-error` : undefined;
  return (
    <div>
      <label className="form-switch">
        <input
          ref={ref}
          id={inputId}
          type="checkbox"
          role="switch"
          name={name}
          checked={checked}
          disabled={disabled}
          {...rest}
        />
        <span className="form-switch-track">
          <span className="form-switch-thumb" />
        </span>
        <span>{label}</span>
      </label>
      {error && (
        <div id={errorId} className="form-text invalid-feedback">
          {error}
        </div>
      )}
    </div>
  );
});
export default Switch;
