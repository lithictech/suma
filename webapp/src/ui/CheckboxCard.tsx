import CardBody from "./CardBody";
import CardText from "./CardText";
import Checkbox from "./Checkbox";
import "./CheckboxCard.css";
import React from "react";

export interface CheckboxCardProps {
  checked: boolean;
  title?: React.ReactNode;
  text?: React.ReactNode;
  onChange: (checked: boolean) => void;
  name?: string;
  disabled?: boolean;
}

export function CheckboxCard({
  checked,
  title,
  text,
  onChange,
  name,
  disabled = false,
}: CheckboxCardProps) {
  return (
    <label className="card checkable-card checkbox-card">
      <CardBody className="checkbox-card-body">
        <Checkbox name={name} checked={checked} disabled={disabled} onChange={onChange} />
        <div>
          <CardText variant="subtitle">{title}</CardText>
          <CardText variant="subtext">{text}</CardText>
        </div>
      </CardBody>
    </label>
  );
}
