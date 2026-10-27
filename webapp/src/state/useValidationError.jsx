import { t } from "../localization";

/**
 * Return the localized validation error value for an input.
 * @param name Name of the input.
 * @param errors Errors from react-hook-form.
 * @param validations Object like {required: true, minLength: 3}.
 * @param additionalErrorKeys Object like {min: "forms.invalid_min_amount"}.
 * @param {string=} label Visible label of the field. When given, a missing required value
 *   names the field and says how to fix it, instead of only "This field is required" (3.3.3).
 * @param {boolean=} isChoice True for a select, so the message says to choose an option.
 * @returns {null|string}
 */
export default function useValidationError(
  name,
  errors,
  validations,
  additionalErrorKeys = {},
  label = null,
  isChoice = false
) {
  const err = errors && errors[name];
  if (!err) {
    return null;
  }
  const allErrKeys = { ...errorKeys, ...additionalErrorKeys };
  let errKey = allErrKeys[err.type] || "forms.invalid_field";
  if (err.type === "required" && label && !additionalErrorKeys.required) {
    errKey = isChoice ? "forms.invalid_required_choose" : "forms.invalid_required_named";
  }
  const message = t(errKey, {
    constraint: validations[err.type],
    value: err.ref.value,
    field: label,
  });
  return message;
}

const errorKeys = {
  required: "forms.invalid_required",
  minLength: "forms.invalid_min_length",
  maxLength: "forms.invalid_max_length",
  min: "forms.invalid_min",
};
