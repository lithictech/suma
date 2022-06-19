import useValidationError from "../state/useValidationError";
import FormText from "./FormText";
import _ from "lodash";
import React from "react";
import Form from "react-bootstrap/Form";
import InputGroup from "react-bootstrap/InputGroup";

/**
 * Represents a Bootstrap Form.Group, Form.Control, and related components.
 * @param {string} name 'name' attribute for the input (and validation)
 * @param {string} className Form.Group class name.
 * @param {JSX.Element} as The 'as' for the Form.Group.
 * @param {string|JSX.Element} label Text or element for the form label.
 * @param {string} text Helper that goes in a Form.Text.
 * @param {JSX.Element} Input The input component to use, default to Form.Control.
 * @param register The react-hook-form register function.
 * @param errors Something like `formState: { errors }` from react-hook-form.
 * @param {object} errorKeys See useValidationError. Some default error messages for validations are supported;
 *   if you need a custom message, you can pass in something like: `{min: "forms:invalid_min_amount"}`.
 * @param {boolean} required HTML5
 * @param {string} pattern HTML5
 * @param {number} minLength HTML5
 * @param {number} maxLength HTML5
 * @param {number} min HTML5
 * @param prepend Content to render before the input. Will use an InputGroup if given.
 * @param append Content to render after the input. Will use an InputGroup if given.
 * @param rest Passed through to the component.
 */
export default function FormControlGroup({
  name,
  className,
  as,
  label,
  text,
  Input,
  register,
  errors,
  errorKeys,
  required,
  pattern,
  minLength,
  maxLength,
  min,
  prepend,
  append,
  ...rest
}) {
  const usesGroup = prepend || append;
  const registerArgs = {};
  if (required) {
    registerArgs.required = true;
  }
  if (minLength) {
    registerArgs.minLength = minLength;
  }
  if (maxLength) {
    registerArgs.maxLength = maxLength;
  }
  if (pattern) {
    registerArgs.pattern = pattern;
  }
  if (min) {
    registerArgs.min = min;
  }
  const message = useValidationError(name, errors, registerArgs, errorKeys);
  const C = Input || Form.Control;
  const input = (
    <C {...register(name, registerArgs)} name={name} isInvalid={!!message} {...rest} />
  );
  return (
    <Form.Group className={className} controlId={name} as={as}>
      {_.isString(label) ? <Form.Label>{label}</Form.Label> : label}
      {usesGroup ? (
        <InputGroup hasValidation>
          {prepend}
          {input}
          {append}
          <Form.Control.Feedback type="invalid">{message}</Form.Control.Feedback>
        </InputGroup>
      ) : (
        <>
          {input}
          <Form.Control.Feedback type="invalid">{message}</Form.Control.Feedback>
        </>
      )}
      {text && <FormText>{text}</FormText>}
    </Form.Group>
  );
}
