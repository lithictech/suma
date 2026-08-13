import useId from "../state/useId.js";
import clsx from "clsx";
import React from "react";

// For furture use with TypeScript conversion:
// export interface TextInputProps {
//   /** Visible label text */
//   label: string;
//   /** Optional help text shown below the input */
//   helpText?: string;
//   /** Optional error message; when present, the input is styled as invalid */
//   error?: string;
//   /** Current input value */
//   value: string;
//   /** Change handler */
//   onChange: (value: string) => void;
//   /** Input type, e.g. "text", "email", "password" */
//   type?: string;
//   /** Name attribute for form submission */
//   name?: string;
//   placeholder?: string;
//   required?: boolean;
//   disabled?: boolean;
//   /** Overrides the auto-generated id if you need to reference it elsewhere */
//   id?: string;
// }
//

export default function TextInput({
  label,
  helpText,
  error,
  value,
  onChange,
  type = "text",
  name,
  placeholder,
  required = false,
  disabled = false,
  id,
  className,
}) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const helpTextId = helpText ? `${inputId}-help` : undefined;
  const errorId = error ? `${inputId}-error` : undefined;

  // Both help text and error, if present, are announced via aria-describedby
  const describedBy = [helpTextId, errorId].filter(Boolean).join(" ") || undefined;

  const cls = clsx(className, "form-control", error && "is-invlaid");

  return (
    <div className="form-group">
      <label className="form-label" htmlFor={inputId}>
        {label}
        {required && " *"}
      </label>

      <input
        id={inputId}
        name={name}
        type={type}
        className={cls}
        value={value}
        placeholder={placeholder}
        required={required}
        disabled={disabled}
        aria-describedby={describedBy}
        aria-invalid={error ? true : undefined}
        onChange={(e) => onChange(e.target.value)}
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
}
