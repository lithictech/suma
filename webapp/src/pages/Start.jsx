import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { mdp, t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import { Logger } from "../shared/logger";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import React, { useState } from "react";
import Alert from "react-bootstrap/Alert";
import Form from "react-bootstrap/Form";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const { language } = useI18Next();
  const navigate = useNavigate();
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [agreementChecked, setAgreementChecked] = React.useState(false);
  const showSmsOptInNotice = useToggle(false);
  const [error, setError] = useError();
  const [phone, setPhone] = useState("");

  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  const handlePhoneChange = (e) => {
    const formattedNum = maskPhoneNumber(e.target.value, phone);
    clearErrors();
    setValue("phone", formattedNum);
    setPhone(formattedNum);
  };

  const handleSubmitForm = () => {
    if (!agreementChecked) {
      showSmsOptInNotice.turnOn();
      return;
    }
    showSmsOptInNotice.turnOff();
    submitDisabled.turnOn();
    inputDisabled.turnOn();
    api
      .authStart({
        phone,
        timezone: dayjs.tz.guess(),
        language,
        termsAgreed: true,
      })
      .then((r) =>
        navigate("/one-time-password", {
          state: {
            phoneNumber: phone,
            requiresTermsAgreement: r.data.requiresTermsAgreement,
          },
        })
      )
      .catch((err) => {
        setError(extractErrorCode(err));
        submitDisabled.turnOff();
        inputDisabled.turnOff();
        if (extractErrorCode(err) === "auth_conflict") {
          logger.error("Unexpected auth conflict");
          window.location.reload();
        }
      });
  };
  return (
    <>
      <h2>{t("forms:get_started")}</h2>
      <p id="phoneRequired">{t("forms:get_started_intro")}</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <FormControlGroup
          className="mb-3"
          type="tel"
          name="phone"
          label={t("forms:phone")}
          pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
          register={register}
          errors={errors}
          value={phone}
          aria-describedby="phoneRequired"
          autoComplete="tel"
          autoFocus
          required
          onChange={handlePhoneChange}
        />
        <SignupAgreement
          checked={agreementChecked}
          onCheckedChanged={setAgreementChecked}
        />
        <FormError error={error} />
        {showSmsOptInNotice.isOn && (
          <Alert variant="warning" dismissible onClose={showSmsOptInNotice.turnOff}>
            Suma uses SMS to provide you access to your account. You'll need to check the
            box to continue.
          </Alert>
        )}
        <FormButtons
          back
          primaryProps={{
            children: t("forms:continue"),
            disabled: submitDisabled.isOn,
          }}
        />
      </Form>
    </>
  );
}

const logger = new Logger("user-auth");

function SignupAgreement({ checked, onCheckedChanged, ...rest }) {
  return (
    <div className="d-flex flex-column">
      <div className="d-flex flex-row">
        <Form.Check
          type="checkbox"
          checked={checked}
          onChange={(e) => onCheckedChanged(e.target.checked)}
          aria-label="Agree to terms"
          {...rest}
        />
        <div id="signup-agreement" className="ms-2 text-secondary small">
          {mdp("auth:sms_optin_signup_agreement", { buttonLabel: t("forms:continue") })}
        </div>
      </div>
      <div className="text-secondary small">
        {mdp("auth:passive_signup_agreement", { buttonLabel: t("forms:continue") })}
      </div>
    </div>
  );
}
