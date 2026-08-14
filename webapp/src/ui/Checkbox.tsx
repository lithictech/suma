import "./Checkbox.css";
import React from "react";

export interface CheckboxProps {
  label?: React.ReactNode;
  checked: boolean;
  onChange: (checked: boolean) => void;
  name?: string;
  disabled?: boolean;
}

export default function Checkbox({
  label,
  checked,
  onChange,
  name,
  disabled = false,
}: CheckboxProps) {
  return (
    <label className="form-check">
      <input
        type="checkbox"
        name={name}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span>{label}</span>
    </label>
  );
}
