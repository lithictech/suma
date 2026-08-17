import useId from "../state/useId.ts";
import CardBody from "./CardBody";
import CardText from "./CardText";
import "./CheckboxCard.css";
import FormFeedback, { HasFormFeedback } from "./FormFeedback.tsx";
import clsx from "clsx";
import React from "react";

export interface CheckboxCardProps
  extends HasFormFeedback,
    Omit<React.InputHTMLAttributes<HTMLInputElement>, "checked" | "type" | "title"> {
  checked: boolean;
  title?: React.ReactNode;
  text?: React.ReactNode;
  name?: string;
  alignCheckbox?: "start" | "center" | "end";
  children?: React.ReactNode;
}

const CheckboxCard = React.forwardRef<HTMLInputElement, CheckboxCardProps>(
  function CheckboxCard(
    {
      id,
      title,
      text,
      error,
      alignCheckbox = "center",
      children,
      ...rest
    }: CheckboxCardProps,
    ref
  ) {
    const inputId = useId(id);
    const labeledBy = `${inputId}-label`;
    return (
      <label
        className={clsx("card checkable-card checkbox-card", error ? "is-invalid" : "")}
      >
        <CardBody className={clsx("checkbox-card-body", `align-items-${alignCheckbox}`)}>
          <input
            ref={ref}
            id={inputId}
            type="checkbox"
            aria-describedby={FormFeedback.idFor(inputId)}
            aria-invalid={error ? true : undefined}
            {...rest}
          />
          <div id={labeledBy}>
            {title && <CardText variant="subtitle">{title}</CardText>}
            {text && <CardText variant="subtext">{text}</CardText>}
            {children && children}
            <FormFeedback inputId={inputId} error={error} />
          </div>
        </CardBody>
      </label>
    );
  }
);
export default CheckboxCard;
