import "./CheckableCard.css";
import clsx from "clsx";
import React from "react";

// export interface CheckableCardProps {
//   checked: boolean;
//   onChange: (checked: boolean) => void;
//   name?: string;
//   disabled?: boolean;
//   children: ComponentChildren;
// }

export default function CheckableCard({
  checked,
  onChange,
  name,
  disabled = false,
  className,
  style,
  children,
}) {
  const cls = clsx("card checkable-card checkable-card-hidecheck", className);
  return (
    <label className={cls} style={style}>
      <input
        type="checkbox"
        name={name}
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
      />
      {children}
    </label>
  );
}
