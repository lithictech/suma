import { t } from "../localization";
import React from "react";
import Form from "react-bootstrap/Form";

export default function SignupAgreement({ checked, onCheckedChanged, ...rest }) {
  return (
    <div className="d-flex">
      <Form.Check
        type="checkbox"
        checked={checked}
        onChange={(e) => onCheckedChanged(e.target.checked)}
        aria-label={t("auth.agree_aria_label")}
        {...rest}
      />
      <div id="signup-agreement" className="ms-2 text-secondary small">
        {t("auth.sign_up_agreement", { buttonLabel: t("forms.continue") })}
      </div>
    </div>
  );
}
