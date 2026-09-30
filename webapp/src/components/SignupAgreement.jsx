import { t } from "../localization";
import FormError from "./FormError.jsx";
import React from "react";
import Form from "react-bootstrap/Form";

export default function SignupAgreement({ errors, register, ...rest }) {
  const inputRef = React.useRef(null);

  const { ref: rhfRef, ...registerRest } = register("agree", {
    validate: (value) => value === true || t("common.agree_to_continue"),
  });

  function handleDivClick(e) {
    // avoid double-toggling if the user clicked the input/label directly
    if (e.target === inputRef.current) {
      return;
    }
    inputRef.current?.click();
  }

  return (
    <div className="d-flex signup-agreement-component" onClick={handleDivClick}>
      <Form.Check
        type="checkbox"
        aria-labelledby="signup-agreement"
        aria-describedby={errors.agree ? "signup-agreement-error" : undefined}
        aria-invalid={errors.agree ? true : undefined}
        required
        isInvalid={!!errors.agree}
        {...registerRest}
        ref={(el) => {
          rhfRef(el);
          inputRef.current = el;
        }}
        {...rest}
      />
      <div className="d-flex flex-column">
        <div id="signup-agreement" className="ms-2 small">
          {t("auth.sign_up_agreement", { buttonLabel: t("forms.continue") })}
        </div>
        <FormError
          id="signup-agreement-error"
          error={<>{errors.agree?.message}</>}
          noMargin
          className="mt-2"
        ></FormError>
      </div>
    </div>
  );
}
