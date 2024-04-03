import useValidationError from "../state/useValidationError";
import FormText from "./FormText";
import React from "react";
import Form from "react-bootstrap/Form";

/**
 * Represents a list of Bootstrap Form.Check radio inputs that passes
 * react-hook-form validation.
 * @param {Array<{id: string, label: string|JSX.Element}>} inputs List of
 *  objects with id and label props of the radio inputs to render. The id will
 *  be compared against the selected value to check the appropriate radio input.
 * @param {string} selected The value to compare against the checked radio id.
 * @param {string} name 'name' attribute for the input (and validation)
 * @param {string} className Form.Check classname attribute.
 * @param {string} text Helper that goes in a Form.Text.
 * @param {function} onChange Handles input changes with radio element event.
 * @param {boolean} required Adds react-hook-form validation
 * @param register The react-hook-form register function.
 * @param errors Something like `formState: { errors }` from react-hook-form.
 * @param rest Passed through to the component.
 */
export default function FormRadioInputs({
  inputs,
  selected,
  name,
  className,
  // eslint-disable-next-line no-unused-vars
  text,
  onChange,
  required,
  register,
  errors,
  ...rest
}) {
  const registerOptions = { required };
  const message = useValidationError(name, errors, registerOptions, {
    required: "forms:invalid_radio_or_checkbox",
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
          isInvalid={!!message}
          checked={selected === id}
          onChange={onChange}
          {...rest}
        />
      ))}
      {message && (
        <Form.Control.Feedback type="invalid" className="d-block">
          {message}
        </Form.Control.Feedback>
      )}
      {text && <FormText>{text}</FormText>}
    </>
  );
}
