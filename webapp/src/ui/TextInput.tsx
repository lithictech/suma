import useId from "../state/useId";
import clsx from "clsx";
import React from "react";

export interface TextInputProps {
  label: React.ReactNode;
  helpText?: React.ReactNode;
  error?: React.ReactNode;
  value: string;
  onChange: (value: string) => void;
  type?: string;
  name?: string;
  placeholder?: string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
  className?: string;
}

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
}: TextInputProps) {
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
