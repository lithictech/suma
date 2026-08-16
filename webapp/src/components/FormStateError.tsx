import { t } from "../localization";
import FormError from "../ui/FormError";
import isEmpty from "lodash/isEmpty";
import React from "react";

interface FormStateErrorProps {
  formState: { errors: Record<string, any> };
  [rest: string]: any;
}

/**
 * Same as FormError but pass in react-hook-form formState.
 */
const FormStateError = React.forwardRef<HTMLElement, FormStateErrorProps>(
  ({ formState, ...rest }, ref) => {
    const error = isEmpty(formState.errors) ? null : (
      <>{t("forms.invalid_fields_submit")}</>
    );
    return <FormError ref={ref} error={error} {...rest} />;
  }
);

export default FormStateError;
