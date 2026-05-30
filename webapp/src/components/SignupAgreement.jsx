import { t } from "../localization";
import FormError from "./FormError.jsx";
import React from "react";
import Form from "react-bootstrap/Form";

export default function SignupAgreement({
  checked,
  errors,
  register,
  onCheckedChanged,
  ...rest
}) {
  function handleClick() {
    onCheckedChanged(!checked);
  }
  return (
    <div className="d-flex signup-agreement-component" onClick={handleClick}>
      <Form.Check
        type="checkbox"
        checked={checked}
        aria-label={t("auth.agree_aria_label")}
        required
        isInvalid={!!errors.agree}
        {...register("agree", {
          validate: (value) => value === true || t("common.agree_to_continue"),
        })}
        {...rest}
        onChange={(e) => onCheckedChanged(e.target.checked)}
      />
      <div className="d-flex flex-column">
        <div id="signup-agreement" className="ms-2 small">
          {t("auth.sign_up_agreement", { buttonLabel: t("forms.continue") })}
        </div>
        <FormError
          error={<>{errors.agree?.message}</>}
          noMargin
          className="mt-2"
        ></FormError>
      </div>
    </div>
  );
}
