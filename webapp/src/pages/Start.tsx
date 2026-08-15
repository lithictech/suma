import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import PhoneInput from "../components/PhoneInput";
import SignupAgreement from "../components/SignupAgreement";
import { MdLink } from "../components/SumaMarkdown";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import { dayjs } from "../modules/dayConfig";
import { Logger } from "../shared/logger";
import { extractErrorCode, extractLocalizedError, useError } from "../state/useError";
import useToggle from "../state/useToggle";
import Form from "../ui/Form";
import React, { useState } from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const { currentLanguage } = useI18n();
  const navigate = useNavigate();
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
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

  const handlePhoneChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    formattedNum: string
  ) => {
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
      .then((r: any) =>
        navigate("/one-time-password", {
          state: {
            phoneNumber: phone,
            requiresTermsAgreement: r.data.requiresTermsAgreement,
          },
        })
      )
      .catch((err: any) => {
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
        <SignupAgreement register={register} errors={errors} />
        <FormError error={error} />
        <FormButtons
          back
          primaryProps={{
            children: t("forms.continue"),
            disabled: submitDisabled.isOn,
          }}
        />
      </Form>
    </>
  );
}

const logger = new Logger("user-auth");
