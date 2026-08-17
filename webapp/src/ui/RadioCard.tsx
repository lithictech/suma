import useId from "../state/useId";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import "./RadioCard.css";
import clsx from "clsx";
import React from "react";

export interface RadioOption<T extends string = string> {
  value: T;
  label: React.ReactNode;
}

export interface RadioCardProps<T extends string = string> extends HasFormFeedback {
  /** Shared name so the browser treats these as one mutually-exclusive group */
  name: string;
  /** Accessible group label, rendered as the fieldset's <legend> */
  legend?: string;
  options: RadioOption<T>[];
  value: T;
  onValueChange: (value: T) => void;
  disabled?: boolean;
  required?: boolean;
  className?: string;
}

interface RadioCardComponent {
  <T extends string = string>(
    props: RadioCardProps<T> & { ref?: React.Ref<HTMLFieldSetElement> }
  ): React.ReactElement | null;
}

const RadioCard = React.forwardRef(function RadioCard<T extends string = string>(
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
  }: RadioCardProps<T>,
  ref: React.Ref<HTMLFieldSetElement>
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
}) as RadioCardComponent;
export default RadioCard;
