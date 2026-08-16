import CardBody from "./CardBody";
import CardText from "./CardText";
import Checkbox, { CheckboxProps } from "./Checkbox";
import "./CheckboxCard.css";
import clsx from "clsx";
import React from "react";

export interface CheckboxCardProps extends Omit<CheckboxProps, "title"> {
  checked: boolean;
  title?: React.ReactNode;
  text?: React.ReactNode;
  name?: string;
  disabled?: boolean;
  centerCheckbox?: boolean;
  children?: React.ReactNode;
}

const CheckboxCard = React.forwardRef<HTMLInputElement, CheckboxCardProps>(
  function CheckboxCard(
    { title, text, error, centerCheckbox = false, children, ...rest }: CheckboxCardProps,
    ref
  ) {
    const hasText = title || text;
    return (
      <label
        className={clsx("card checkable-card checkbox-card", error ? "is-invalid" : "")}
      >
        <CardBody
          className={clsx(
            "checkbox-card-body",
            centerCheckbox ? "align-items-start" : ""
          )}
        >
          <Checkbox ref={ref} error={error} {...rest} />
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
);
export default CheckboxCard;
