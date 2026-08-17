import "./RadioCard.css";
import React from "react";

export interface RadioOption {
  value: string;
  label: React.ReactNode;
}

export interface RadioCardProps {
  /** Shared name so the browser treats these as one mutually-exclusive group */
  name: string;
  /** Accessible group label, rendered as the fieldset's <legend> */
  legend?: string;
  options: RadioOption[];
  value: string;
  onValueChange: (value: string) => void;
  disabled?: boolean;
}

export default function RadioCard({
  name,
  legend,
  options,
  value,
  onValueChange,
  disabled = false,
}: RadioCardProps) {
  return (
    <fieldset className="card radio-card">
      {legend && <legend>{legend}</legend>}
      {options.map((option) => (
        <label key={option.value}>
          <input
            type="radio"
            name={name}
            value={option.value}
            checked={value === option.value}
            disabled={disabled}
            onChange={() => onValueChange(option.value)}
          />
          {option.label}
        </label>
      ))}
    </fieldset>
  );
}
