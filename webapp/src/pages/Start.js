import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import { Logger } from "../shared/logger";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import React, { useState } from "react";
import Form from "react-bootstrap/Form";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const { language } = useI18Next();
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

  const handlePhoneChange = (e) => {
    const formattedNum = maskPhoneNumber(e.target.value, phone);
    clearErrors();
    setValue("phone", formattedNum);
    setPhone(formattedNum);
  };

  const handleSubmitForm = () => {
    submitDisabled.turnOn();
    inputDisabled.turnOn();
    api
      .authStart({
        phone,
        timezone: dayjs.tz.guess(),
        language,
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
          name="phone"
          label={t("forms:phone")}
          pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
          register={register}
          errors={errors}
          value={phone}
          onChange={handlePhoneChange}
          aria-describedby="phoneRequired"
          autoComplete="tel-national"
          autoFocus
          required
        />
        <FormError error={error} />
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
