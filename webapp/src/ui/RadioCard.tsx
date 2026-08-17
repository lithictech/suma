import useId from "../state/useId";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import "./RadioCard.css";
import clsx from "clsx";
import React from "react";

export interface RadioOption {
  value: string;
  label: React.ReactNode;
}

export interface RadioCardProps extends HasFormFeedback {
  /** Shared name so the browser treats these as one mutually-exclusive group */
  name: string;
  /** Accessible group label, rendered as the fieldset's <legend> */
  legend?: string;
  options: RadioOption[];
  value: string;
  onValueChange: (value: string) => void;
  disabled?: boolean;
  required?: boolean;
  className?: string;
}

const RadioCard = React.forwardRef<HTMLFieldSetElement, RadioCardProps>(
  function RadioCard(
    {
      name,
      legend,
      options,
      value,
      onValueChange,
      disabled = false,
      required = false,
      error,
      help,
      className,
    },
    ref
  ) {
    const groupId = useId();
    return (
      <div>
        <fieldset
          ref={ref}
          className={clsx("card radio-card", className)}
          aria-describedby={FormFeedback.idFor(groupId)}
        >
          {legend && (
            <legend>
              {legend}
              {required && <span className="ml-1 color-danger">*</span>}
            </legend>
          )}
          {options.map((option) => (
            <label key={option.value} className="radio-card-option">
              <input
                type="radio"
                name={name}
                value={option.value}
                checked={value === option.value}
                disabled={disabled}
                required={required}
                onChange={() => onValueChange(option.value)}
              />
              {option.label}
            </label>
          ))}
        </fieldset>
        <FormFeedback inputId={groupId} error={error} help={help} />
      </div>
    );
  }
);
export default RadioCard;
