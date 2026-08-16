import CardBody from "./CardBody";
import CardText from "./CardText";
import Checkbox from "./Checkbox";
import "./CheckboxCard.css";
import clsx from "clsx";
import React from "react";

export interface CheckboxCardProps {
  checked: boolean;
  title?: React.ReactNode;
  text?: React.ReactNode;
  onChange: (checked: boolean) => void;
  name?: string;
  disabled?: boolean;
  centerCheckbox?: boolean;
  children?: React.ReactNode;
}

export function CheckboxCard({
  checked,
  title,
  text,
  onChange,
  name,
  disabled = false,
  centerCheckbox = false,
  children,
}: CheckboxCardProps) {
  const hasText = title || text;
  return (
    <label className="card checkable-card checkbox-card">
      <CardBody
        className={clsx("checkbox-card-body", centerCheckbox ? "align-items-start" : "")}
      >
        <Checkbox name={name} checked={checked} disabled={disabled} onChange={onChange} />
        {hasText && (
          <div>
            {title && <CardText variant="subtitle">{title}</CardText>}
            {text && <CardText variant="subtext">{text}</CardText>}
          </div>
        )}
        {children && <div className="checkable-card-content">{children}</div>}
      </CardBody>
    </label>
  );
}
