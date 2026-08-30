import useId from "../state/useId";
import InputFeedback, { HasInputFeedback } from "./InputFeedback.tsx";
import clsx from "clsx";
import React from "react";

export interface TextInputProps
  extends HasInputFeedback,
    React.DetailedHTMLProps<
      React.InputHTMLAttributes<HTMLInputElement>,
      HTMLInputElement
    > {
  label: React.ReactNode;
  inputClass?: string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
  className?: string;
}

const TextInput = React.forwardRef<HTMLInputElement, TextInputProps>(function TextInput(
  {
    label,
    help,
    error,
    id,
    className,
    inputClass,
    required = false,
    disabled = false,
    ...rest
  }: TextInputProps,
  ref
) {
  const inputId = useId(id);
  const cls = clsx("form-control", error && "is-invalid", inputClass);
  return (
    <div className={clsx("form-group", className)}>
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
        aria-describedby={InputFeedback.idFor(inputId)}
        aria-invalid={error ? true : undefined}
        {...rest}
      />
      <InputFeedback inputId={inputId} help={help} error={error} />
    </div>
  );
});
export default TextInput;
