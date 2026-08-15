import { t } from "../localization";
import FormCheck from "../ui/FormCheck";
import FormError from "./FormError";
import React from "react";
import { FieldErrors, FieldValues, UseFormRegister } from "react-hook-form";

interface SignupAgreementProps {
  errors: FieldErrors;
  register: UseFormRegister<FieldValues>;
  [rest: string]: any;
}

export default function SignupAgreement({
  errors,
  register,
  ...rest
}: SignupAgreementProps) {
  const inputRef = React.useRef<HTMLInputElement>(null);

  const { ref: rhfRef, ...registerRest } = register("agree", {
    validate: (value: boolean) => value === true || t("common.agree_to_continue"),
  });

  function handleDivClick(e: React.MouseEvent) {
    // avoid double-toggling if the user clicked the input/label directly
    if (e.target === inputRef.current) {
      return;
    }
    inputRef.current?.click();
  }

  return (
    <div className="d-flex signup-agreement-component" onClick={handleDivClick}>
      <FormCheck
        type="checkbox"
        aria-label={t("auth.agree_aria_label")}
        required
        isInvalid={!!errors.agree}
        {...registerRest}
        ref={(el: HTMLInputElement) => {
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
          error={<>{errors.agree?.message}</>}
          noMargin
          className="mt-2"
        ></FormError>
      </div>
    </div>
  );
}
