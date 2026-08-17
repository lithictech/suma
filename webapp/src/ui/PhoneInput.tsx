import { isValidPhone, buildValidators } from "../modules/formValidators";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import TextInput, { TextInputProps } from "./TextInput";
import React from "react";
import { Control, useController, UseFormClearErrors } from "react-hook-form";

export interface PhoneInputProps
  extends Omit<TextInputProps, "name" | "value" | "onChange" | "onBlur" | "error"> {
  /** react-hook-form field name for this input. */
  name: string;
  /** react-hook-form `control`, from `useForm()`. */
  control: Control<any>;
  /**
   * Optional: if given, the field's error is cleared as soon as the typed value
   * becomes a valid phone number, rather than waiting for the form's normal
   * validation timing (mode/reValidateMode) to catch up. Values are only ever
   * flagged as *invalid* on that normal schedule (eg on blur) - this only makes
   * clearing an existing error more responsive while the user is still typing.
   */
  clearErrors?: UseFormClearErrors<any>;
}

/**
 * A phone number input wired directly to react-hook-form: owns its own
 * masking, validation rule, and field registration via `useController`.
 * Callers just need `name` + `control` - no manual `register`/`setValue`
 * plumbing, no local state for the masked value.
 */
export default function PhoneInput({
  name,
  control,
  clearErrors,
  required,
  ...rest
}: PhoneInputProps) {
  const {
    field: { onChange, onBlur, value, ref },
    fieldState: { error },
  } = useController({
    name,
    control,
    rules: buildValidators({ phone: true, required: true }),
  });

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    const formattedNum = maskPhoneNumber(e.target.value);
    onChange(formattedNum);
    if (clearErrors && isValidPhone(formattedNum)) {
      clearErrors(name);
    }
  }

  return (
    <TextInput
      ref={ref}
      type="tel"
      name={name}
      autoComplete="tel"
      value={value || ""}
      required={required}
      onChange={handleChange}
      onBlur={onBlur}
      error={error?.message}
      {...rest}
    />
  );
}
