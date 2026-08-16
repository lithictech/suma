import useId from "../state/useId";
import clsx from "clsx";
import React from "react";

export interface TextInputProps
  extends React.DetailedHTMLProps<
    React.InputHTMLAttributes<HTMLInputElement>,
    HTMLInputElement
  > {
  label: React.ReactNode;
  helpText?: React.ReactNode;
  error?: React.ReactNode | string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
  className?: string;
}

const TextInput = React.forwardRef<HTMLInputElement, TextInputProps>(function TextInput(
  {
    label,
    helpText,
    error,
    id,
    className,
    required = false,
    disabled = false,
    ...rest
  }: TextInputProps,
  ref
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const helpTextId = helpText ? `${inputId}-help` : undefined;
  const errorId = error ? `${inputId}-error` : undefined;
  const describedBy = [helpTextId, errorId].filter(Boolean).join(" ") || undefined;
  const cls = clsx(className, "form-control", error && "is-invalid");
  return (
    <div className="form-group">
      <label className="form-label" htmlFor={inputId}>
        {label}
        {required && <span className="ml-1 color-danger">*</span>}
      </label>
      <input
        ref={ref}
        id={inputId}
        className={cls}
        required={required}
        disabled={disabled}
        aria-describedby={describedBy}
        aria-invalid={error ? true : undefined}
        {...rest}
      />
      {helpText && !error && (
        <div id={helpTextId} className="form-text">
          {helpText}
        </div>
      )}
      {error && (
        <div id={errorId} className="form-text invalid-feedback">
          {error}
        </div>
      )}
    </div>
  );
});
export default TextInput;
