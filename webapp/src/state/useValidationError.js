import i18next from "i18next";

/**
 * Return the localized validation error value for an input.
 * @param name Name of the input.
 * @param errors Errors from react-hook-form.
 * @param validations Object like {required: true, minLength: 3}.
 * @returns {null|string}
 */
export default function useValidationError(name, errors, validations) {
  const err = errors && errors[name];
  if (!err) {
    return null;
  }
  const errKey = errorKeys[err.type] || "forms:invalid_field";
  const message = i18next.t(errKey, {
    constraint: validations[err.type],
    value: err.ref.value,
  });
  return message;
}

const errorKeys = {
  required: "forms:invalid_required",
  minLength: "forms:invalid_min_length",
  maxLength: "forms:invalid_max_length",
};
