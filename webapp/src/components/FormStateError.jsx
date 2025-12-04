import { t } from "../localization";
import FormError from "./FormError.jsx";
import isEmpty from "lodash/isEmpty.js";
import React from "react";

/**
 * Same as FormError but pass in react-hook-form formState.
 */
const FormStateError = React.forwardRef(({ formState, ...rest }, ref) => {
  const error = isEmpty(formState.errors) ? null : (
    <>{t("forms.invalid_fields_submit")}</>
  );
  return <FormError ref={ref} error={error} {...rest} />;
});

export default FormStateError;
