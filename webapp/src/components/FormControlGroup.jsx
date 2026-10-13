import { t } from "../localization";
import setRef from "../shared/setRef";
import useValidationError from "../state/useValidationError";
import FormText from "./FormText";
import clsx from "clsx";
import isString from "lodash/isString";
import React from "react";
import Form from "react-bootstrap/Form";
import InputGroup from "react-bootstrap/InputGroup";

/**
 * Represents a Bootstrap Form.Group, Form.Control, and related components.
 * @param inputRef ref for the input element.
 * @param {string} name 'name' attribute for the input (and validation)
 * @param {string} className Form.Group class name.
 * @param {JSX.Element} as The 'as' for the Form.Group.
 * @param {string|JSX.Element} label Text or element for the form label.
 * @param {string|JSX.Element} placeholder Do not use, since we put the label in the form.
 * @param {string} text Helper that goes in a Form.Text.
 * @param {JSX.Element} Input The input component to use, default to Form.Control.
 * @param {string} inputClass Applied to Input element.
 * @param register The react-hook-form register function.
 * @param registerOptions Arguments passed to `register`.
 *   Normally something like `{validate: (value) => value === otherValue}`,
 *   which would be paired with an `errorKeys` like `{validate: 'forms:account_number_confirm_nomatch'}`.
 * @param errors Something like `formState: { errors }` from react-hook-form.
 * @param {object} errorKeys See useValidationError. Some default error messages for validations are supported;
 *   if you need a custom message, you can pass in something like: `{min: "forms.invalid_min_amount"}`.
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
  inputRef,
  name,
  className,
  as,
  label,
  // eslint-disable-next-line no-unused-vars
  placeholder,
  text,
  Input,
  inputClass,
  register,
  registerOptions,
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
  const { "aria-describedby": describedByProp, ...inputProps } = rest;
  const usesGroup = prepend || append;
  const registerArgs = { ...registerOptions };
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
    registerArgs.pattern = isString(pattern) ? new RegExp(pattern) : pattern;
  }
  if (min) {
    registerArgs.min = min;
  }
  const { ref: registerRef, ...registerRest } = register(name, registerArgs);
  const message = useValidationError(name, errors, registerArgs, errorKeys);
  const feedbackId = `${name}-feedback`;
  const textId = `${name}-text`;
  const describedBy =
    [message && feedbackId, text && textId, describedByProp].filter(Boolean).join(" ") ||
    undefined;
  const C = Input || Form.Control;
  const input = (
    <C
      ref={(r) => {
        registerRef(r);
        setRef(inputRef, r);
      }}
      {...registerRest}
      name={name}
      maxLength={maxLength}
      minLength={minLength}
      isInvalid={!!message}
      className={inputClass}
      aria-required={required || undefined}
      aria-invalid={message ? true : undefined}
      aria-describedby={describedBy}
      {...inputProps}
    />
  );
  const feedback = (
    <Form.Control.Feedback id={feedbackId} type="invalid">
      {message}
    </Form.Control.Feedback>
  );
  return (
    <Form.Group className={className} controlId={name} as={as}>
      {isString(label) ? (
        <Form.Label>
          {label}
          {required && <span aria-hidden="true"> *</span>}
        </Form.Label>
      ) : (
        label
      )}
      {usesGroup ? (
        <InputGroup hasValidation>
          {prepend}
          {input}
          {append}
          {feedback}
        </InputGroup>
      ) : (
        <>
          {input}
          {feedback}
        </>
      )}
      {text && <FormText id={textId}>{text}</FormText>}
    </Form.Group>
  );
}

/**
 * One-line legend explaining the '*' marker used on required field labels.
 * Render once near the top of a form that has required fields.
 */
export function RequiredFieldsNote({ className }) {
  return (
    <p className={clsx("small text-muted", className)}>
      {t("forms.required_fields_note")}
    </p>
  );
}
