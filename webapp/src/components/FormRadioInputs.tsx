import useValidationError from "../state/useValidationError";
import Form from "../ui/Form";
import FormText from "./FormText";
import React from "react";
import Form from "react-bootstrap/Form";
import { FieldErrors, FieldValues, UseFormRegister } from "react-hook-form";

interface FormRadioInputsProps {
  /** List of objects with id and label props of the radio inputs to render. The id will
   *  be compared against the selected value to check the appropriate radio input. */
  inputs: { id: string; label: React.ReactNode }[];
  /** The value to compare against the checked radio id. */
  selected?: string;
  /** 'name' attribute for the input (and validation) */
  name: string;
  /** Form.Check classname attribute. */
  className?: string;
  /** Helper that goes in a Form.Text. */
  text?: React.ReactNode;
  /** Handles input changes with radio element event. */
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  /** Adds react-hook-form validation */
  required?: boolean;
  /** The react-hook-form register function. */
  register: UseFormRegister<FieldValues>;
  /** Something like `formState: { errors }` from react-hook-form. */
  errors?: FieldErrors;
  [rest: string]: any;
}

/**
 * Represents a list of Bootstrap Form.Check radio inputs that passes
 * react-hook-form validation.
 */
export default function FormRadioInputs({
  inputs,
  selected,
  name,
  className,
  text,
  onChange,
  required,
  register,
  errors,
  ...rest
}: FormRadioInputsProps) {
  const registerOptions = { required };
  const message = useValidationError(name, errors, registerOptions, {
    required: "forms.invalid_required",
  });
  return (
    <>
      {inputs.map(({ id, label }) => (
        <Form.Check
          {...register(name, registerOptions)}
          key={id}
          id={id}
          value={id}
          label={label}
          type="radio"
          className={className}
          // It's unusual to highlight the checkbox label itself when it's required,
          // but to draw more attention to it, we highlight the label and the tooltip
          // below the checkboxes.
          isInvalid={!!message}
          checked={selected === id}
          onChange={onChange}
          {...rest}
        />
      ))}
      <Form.Control.Feedback type="invalid" className={message ? "d-block" : "d-none"}>
        {message}
      </Form.Control.Feedback>
      {text && <FormText>{text}</FormText>}
    </>
  );
}
