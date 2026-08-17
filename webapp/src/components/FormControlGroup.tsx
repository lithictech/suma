import setRef from "../modules/setRef";
import useValidationError from "../state/useValidationError";
import FormControl from "../ui/FormControl";
import FormControlFeedback from "../ui/FormControlFeedback";
import FormLabel from "../ui/FormLabel";
import InputGroup from "../ui/InputGroup";
import FormText from "./FormText";
import clsx from "clsx";
import isString from "lodash/isString";
import React from "react";
import { FieldErrors, FieldValues, UseFormRegister } from "react-hook-form";

interface FormControlGroupProps {
  inputRef?: React.Ref<any>;
  /** 'name' attribute for the input (and validation) */
  name: string;
  /** Form.Group class name. */
  className?: string;
  /** The 'as' for the Form.Group. */
  as?: React.ElementType;
  /** Text or element for the form label. */
  label?: React.ReactNode;
  /** Do not use, since we put the label in the form. */
  placeholder?: string;
  /** Helper that goes in a Form.Text. */
  text?: React.ReactNode;
  /** The input component to use, default to Form.Control. */
  Input?: React.ElementType;
  /** Applied to Input element. */
  inputClass?: string;
  /** The react-hook-form register function. */
  register: UseFormRegister<FieldValues>;
  /**
   * Arguments passed to `register`.
   * Normally something like `{validate: (value) => value === otherValue}`,
   * which would be paired with an `errorKeys` like `{validate: 'forms:account_number_confirm_nomatch'}`.
   */
  registerOptions?: Record<string, any>;
  /** Something like `formState: { errors }` from react-hook-form. */
  errors?: FieldErrors;
  /**
   * See useValidationError. Some default error messages for validations are supported;
   * if you need a custom message, you can pass in something like: `{min: "forms.invalid_min_amount"}`.
   */
  errorKeys?: Record<string, string>;
  /** HTML5 */
  required?: boolean;
  /** HTML5 */
  pattern?: string;
  /** HTML5 */
  minLength?: number;
  /** HTML5 */
  maxLength?: number;
  /** HTML5 */
  min?: number;
  /** Content to render before the input. Will use an InputGroup if given. */
  prepend?: React.ReactNode;
  /** Content to render after the input. Will use an InputGroup if given. */
  append?: React.ReactNode;
  [rest: string]: any;
}

export default function FormControlGroup({
  inputRef,
  name,
  className,
  as,
  label,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
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
}: FormControlGroupProps) {
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
  const C = Input || FormControl;
  const input = (
    <C
      id={name}
      ref={(r: any) => {
        registerRef(r);
        setRef(inputRef, r);
      }}
      {...registerRest}
      name={name}
      maxLength={maxLength}
      minLength={minLength}
      isInvalid={!!message}
      placeholder={isString(label) ? label : null}
      className={inputClass}
      {...rest}
    />
  );
  const GroupComponent: React.ElementType = as || "div";
  return (
    <GroupComponent className={clsx("form-group", className)}>
      {isString(label) ? (
        <FormLabel htmlFor={name} className="visually-hidden">
          {label}
        </FormLabel>
      ) : (
        label
      )}
      {usesGroup ? (
        <InputGroup hasValidation>
          {prepend}
          {input}
          {append}
          <FormControlFeedback type="invalid">{message}</FormControlFeedback>
        </InputGroup>
      ) : (
        <>
          {input}
          <FormControlFeedback type="invalid">{message}</FormControlFeedback>
        </>
      )}
      {text && <FormText>{text}</FormText>}
    </GroupComponent>
  );
}
