import useId from "../state/useId";
import "./Select.css";
import React from "react";

export interface SelectOption {
  value: string;
  label: React.ReactNode;
}

export interface SelectProps {
  label: React.ReactNode;
  options: SelectOption[];
  value: string;
  onChange: (value: string) => void;
  helpText?: React.ReactNode;
  error?: React.ReactNode;
  placeholder?: string;
  name?: string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
}

export default function Select({
  label,
  options,
  value,
  onChange,
  helpText,
  error,
  placeholder,
  name,
  required = false,
  disabled = false,
  id,
}: SelectProps) {
  const selectId = useId(id);
  const helpTextId = helpText ? `${selectId}-help` : undefined;
  const errorId = error ? `${selectId}-error` : undefined;
  const describedBy = [helpTextId, errorId].filter(Boolean).join(" ") || undefined;
  return (
    <div className="form-group">
      <label className="form-label" htmlFor={selectId}>
        {label}
        {required && " *"}
      </label>
      <div className="select-wrapper">
        <select
          id={selectId}
          name={name}
          className={error ? "is-invalid" : undefined}
          value={value}
          required={required}
          disabled={disabled}
          aria-describedby={describedBy}
          aria-invalid={error ? true : undefined}
          onChange={(e) => onChange(e.target.value)}
        >
          {placeholder && (
            <option value="" disabled hidden>
              {placeholder}
            </option>
          )}
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
        <svg className="select-arrow" viewBox="0 0 12 8" aria-hidden="true">
          <path
            d="M1 1l5 5 5-5"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>
      {helpText && (
        <small id={helpTextId} className="form-text">
          {helpText}
        </small>
      )}
      {error && (
        <span id={errorId} className="invalid-feedback">
          {error}
        </span>
      )}
    </div>
  );
}
