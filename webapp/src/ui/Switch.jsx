import "./Switch.css";
import React from "react";

// export interface SwitchProps {
//   label: string;
//   checked: boolean;
//   onChange: (checked: boolean) => void;
//   name?: string;
//   disabled?: boolean;
// }

export default function Switch({ label, checked, onChange, name, disabled = false }) {
  return (
    <label className="form-switch">
      <input
        type="checkbox"
        role="switch"
        name={name}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      <span className="form-switch-track">
        <span className="form-switch-thumb" />
      </span>
      <span>{label}</span>
    </label>
  );
}
