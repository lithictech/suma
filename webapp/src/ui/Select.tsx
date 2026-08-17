import useId from "../state/useId";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import "./Select.css";
import clsx from "clsx";
import React from "react";

export interface SelectOption<T extends string = string> {
  value: T;
  label: React.ReactNode;
}

export interface SelectProps<T extends string = string>
  extends HasFormFeedback,
    React.InputHTMLAttributes<HTMLSelectElement> {
  label: React.ReactNode;
  options: SelectOption<T>[];
  value?: T;
  placeholder?: string;
  name?: string;
  required?: boolean;
  disabled?: boolean;
  id?: string;
}

interface SelectComponent {
  <T extends string = string>(
    props: SelectProps<T> & { ref?: React.Ref<HTMLSelectElement> }
  ): React.ReactElement | null;
}

const Select = React.forwardRef(function Select<T extends string = string>(
  {
    label,
    options,
    value,
    help,
    error,
    placeholder,
    name,
    required = false,
    disabled = false,
    id,
    className,
    ...rest
  }: SelectProps<T>,
  ref: React.Ref<HTMLSelectElement>
) {
  const selectId = useId(id);
  return (
    <div className={clsx("form-group", className)}>
      <label className="form-label" htmlFor={selectId}>
        {label}
        {required && " *"}
      </label>
      <div className="select-wrapper">
        <select
          ref={ref}
          id={selectId}
          name={name}
          className={error ? "is-invalid" : undefined}
          value={value}
          required={required}
          disabled={disabled}
          aria-describedby={FormFeedback.idFor(selectId)}
          aria-invalid={error ? true : undefined}
          {...rest}
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
      <FormFeedback inputId={selectId} help={help} error={error} />
    </div>
  );
}) as SelectComponent;
export default Select;
