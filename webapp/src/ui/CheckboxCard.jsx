import CardBody from "./CardBody.jsx";
import CardText from "./CardText.jsx";
import Checkbox from "./Checkbox.jsx";
import "./CheckboxCard.css";
import React from "react";

// import type { ComponentChildren } from "preact";
//
// export interface CardWithCheckboxProps {
//   checked: boolean;
//   onChange: (checked: boolean) => void;
//   name?: string;
//   disabled?: boolean;
//   children: ComponentChildren;
// }

export function CheckboxCard({ checked, title, text, onChange, name, disabled = false }) {
  return (
    <label className="card checkable-card checkbox-card">
      <CardBody className="checkbox-card-body">
        <Checkbox
          name={name}
          checked={checked}
          disabled={disabled}
          onChange={(e) => onChange(e.target.checked)}
        />
        <div>
          <CardText variant="subhead">{title}</CardText>
          <CardText variant="subtext">{text}</CardText>
        </div>
      </CardBody>
    </label>
  );
}
