import "./Checkbox.css";
import React from "react";

// export interface CheckboxProps {
//   label: string;
//   checked: boolean;
//   onChange: (checked: boolean) => void;
//   name?: string;
//   disabled?: boolean;
// }

export default function Checkbox({ label, checked, onChange, name, disabled = false }) {
  return (
    <label className="form-check">
      <input
        type="checkbox"
        name={name}
        checked={checked}
        disabled={disabled}
        onChange={onChange}
      />
      <span>{label}</span>
    </label>
  );
}
