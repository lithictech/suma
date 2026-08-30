import { r } from "../localization";
import isString from "lodash/isString";
import { Message, ValidationRule } from "react-hook-form";

export function isValidPhone(s: string) {
  return PHONE_RE.test(s);
}

const PHONE_RE = /^\(\d{3}\) \d{3}-\d{4}$/;

interface BuildValidatorsProps {
  required?: boolean;
  phone?: boolean;
  minLength?: number;
  maxLength?: number;
  min?: number;
  pattern?: string | RegExp;
}

/**
 * The subset of RHF's RegisterOptions that buildValidators actually produces.
 * Typed against RHF's own field-independent pieces (ValidationRule/Message)
 * rather than the full generic RegisterOptions<TFieldValues, TFieldName>, so
 * the result is structurally assignable to register()'s options for any
 * form/field - none of these keys (unlike eg `deps`/`validate`) depend on the
 * specific form's shape, so there's nothing to parameterize here.
 */
export interface BuiltValidators {
  required?: ValidationRule<boolean> | Message;
  minLength?: ValidationRule<number>;
  maxLength?: ValidationRule<number>;
  pattern?: ValidationRule<RegExp>;
  min?: ValidationRule<number | string>;
}

export function buildValidators({
  required,
  phone,
  minLength,
  maxLength,
  min,
  pattern,
}: BuildValidatorsProps): BuiltValidators {
  const result: BuiltValidators = {};
  if (required) {
    result.required = { value: true, message: r("forms.invalid_required") };
  }
  if (minLength) {
    result.minLength = {
      value: minLength,
      message: r("forms.invalid_min_length", { constraint: minLength }),
    };
  }
  if (maxLength) {
    result.maxLength = {
      value: maxLength,
      message: r("forms.invalid_max_length", { constraint: maxLength }),
    };
  }
  if (min) {
    result.min = { value: min, message: r("forms.invalid_min", { constraint: min }) };
  }
  if (pattern) {
    result.pattern = {
      value: isString(pattern) ? new RegExp(pattern) : pattern,
      message: r("forms.invalid_field"),
    };
  }
  if (phone) {
    result.pattern = {
      value: PHONE_RE,
      message: r("errors.impossible_phone_number"),
    };
  }
  return result;
}
