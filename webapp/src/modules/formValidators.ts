import { t } from "../localization";
import isString from "lodash/isString";
import { RegisterOptions } from "react-hook-form";

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

export function buildValidators({
  required,
  phone,
  minLength,
  maxLength,
  min,
  pattern,
}: BuildValidatorsProps): RegisterOptions {
  const result = {} as RegisterOptions;
  if (required) {
    result.required = { value: true, message: t("forms.invalid_required") };
  }
  if (minLength) {
    result.minLength = { value: minLength, message: t("forms.invalid_min_length") };
  }
  if (maxLength) {
    result.maxLength = { value: maxLength, message: t("forms.invalid_max_length") };
  }
  if (pattern) {
    result.pattern = {
      value: isString(pattern) ? new RegExp(pattern) : pattern,
      message: t("forms.invalid_field"),
    };
  }
  if (min) {
    result.min = min;
  }
  if (phone) {
    result.pattern = {
      value: PHONE_RE,
      message: t("errors.impossible_phone_number"),
    };
  }
  return result;
}
