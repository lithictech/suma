import { t } from "../localization";

/**
 * Return parameters passed to a RHF register function.
 */
export function validPhoneInput() {
  return {
    pattern: {
      value: PHONE_RE,
      message: t("errors.impossible_phone_number"),
    },
  };
}

export function isValidPhone(s: string) {
  return PHONE_RE.test(s);
}

const PHONE_RE = /^\(\d{3}\) \d{3}-\d{4}$/;

export function requiredInput(required: boolean | null | undefined) {
  if (!required) {
    return {};
  }
  return { required: t("forms.invalid_required") };
}
