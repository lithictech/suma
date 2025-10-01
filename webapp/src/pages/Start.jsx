import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import PhoneInput from "../components/PhoneInput.jsx";
import SignupAgreement from "../components/SignupAgreement";
import { MdLink } from "../components/SumaMarkdown.jsx";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import { dayjs } from "../modules/dayConfig";
import { Logger } from "../shared/logger";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, extractLocalizedError, useError } from "../state/useError";
import React, { useState } from "react";
import Form from "react-bootstrap/Form";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const { currentLanguage } = useI18n();
  const navigate = useNavigate();
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [agreementChecked, setAgreementChecked] = React.useState(false);
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

  const handlePhoneChange = (e, formattedNum) => {
    clearErrors();
    setValue("phone", formattedNum);
    setPhone(formattedNum);
  };

  const handleSubmitForm = () => {
    submitDisabled.turnOn();
    inputDisabled.turnOn();
    setError(null);
    api
      .authStart({
        phone,
        timezone: dayjs.tz.guess(),
        language: currentLanguage,
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
        setError(extractLocalizedError(err));
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
      <h2>{t("forms.get_started")}</h2>
      <p id="phoneRequired">{t("forms.get_started_intro")}</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <PhoneInput
          className="mb-3"
          name="phone"
          label={t("forms.phone")}
          register={register}
          errors={errors}
          value={phone}
          aria-describedby="phoneRequired"
          autoFocus
          required
          onPhoneChange={handlePhoneChange}
        />
        <p>
          {t(
            "auth.phone_number_changed",
            {},
            {
              markdown: {
                overrides: { a: { component: MdLink, props: { immediate: true } } },
              },
            }
          )}
        </p>
        <SignupAgreement
          checked={agreementChecked}
          onCheckedChanged={setAgreementChecked}
        />
        <FormError error={error} />
        <FormButtons
          back
          primaryProps={{
            children: t("forms.continue"),
            disabled: submitDisabled.isOn || !agreementChecked,
          }}
        />
      </Form>
    </>
  );
}

const logger = new Logger("user-auth");
