import useValidationError from "../state/useValidationError";
import React from "react";
import Form from "react-bootstrap/Form";

export default function FormControlGroup({
  name,
  className,
  as,
  label,
  Component,
  register,
  errors,
  required,
  pattern,
  minLength,
  maxLength,
  ...rest
}) {
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
  const C = Component || Form.Control;
  const message = useValidationError(name, errors, registerArgs);
  return (
    <Form.Group className={className} controlId={name} as={as}>
      <Form.Label>{label}</Form.Label>
      <C {...register(name, registerArgs)} name={name} isInvalid={!!message} {...rest} />
      <Form.Control.Feedback type="invalid">{message}</Form.Control.Feedback>
    </Form.Group>
  );
}
