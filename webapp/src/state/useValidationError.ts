import { r } from "../localization";

/**
 * Return the localized validation error value for an input.
 * @param name Name of the input.
 * @param errors Errors from react-hook-form.
 * @param validations Object like {required: true, minLength: 3}.
 * @param additionalErrorKeys Object like {min: "forms.invalid_min_amount"}.
 */
export default function useValidationError(
  name: string,
  errors: any,
  validations: any,
  additionalErrorKeys: Record<string, string> = {}
): string | null {
  const err = errors && errors[name];
  if (!err) {
    return null;
  }
  const allErrKeys = { ...errorKeys, ...additionalErrorKeys };
  const errKey = allErrKeys[err.type] || "forms.invalid_field";
  const message = r(errKey, {
    constraint: validations[err.type],
    value: err.ref.value,
  });
  return message;
}

const errorKeys: Record<string, string> = {
  required: "forms.invalid_required",
  minLength: "forms.invalid_min_length",
  maxLength: "forms.invalid_max_length",
  min: "forms.invalid_min",
};
