import useValidationError from "../state/useValidationError";
import React from "react";
import Form from "react-bootstrap/Form";
import InputGroup from "react-bootstrap/InputGroup";

export default function FormControlGroup({
  name,
  className,
  as,
  label,
  text,
  Component,
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
  const C = Component || Form.Control;
  const message = useValidationError(name, errors, registerArgs, errorKeys);
  return (
    <Form.Group className={className} controlId={name} as={as}>
      <Form.Label>{label}</Form.Label>
      {usesGroup ? (
        <InputGroup hasValidation>
          {prepend}
          <C {...register(name, registerArgs)} name={name} isInvalid={!!message} {...rest} />
          {append}
          <Form.Control.Feedback type="invalid">{message}</Form.Control.Feedback>
        </InputGroup>
      ) : (
        <>
          <C {...register(name, registerArgs)} name={name} isInvalid={!!message} {...rest} />
          <Form.Control.Feedback type="invalid">{message}</Form.Control.Feedback>
        </>
      )}
      {text && <Form.Text>{text}</Form.Text>}
    </Form.Group>
  );
}
