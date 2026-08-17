import api from "../../api";
import SignupAgreement from "../../components/SignupAgreement";
import { MdLink } from "../../components/SumaMarkdown";
import { t } from "../../localization";
import useI18n from "../../localization/useI18n";
import { dayjs } from "../../modules/dayConfig";
import { Logger } from "../../modules/logger";
import { extractErrorCode, extractLocalizedError, useError } from "../../state/useError";
import useToggle from "../../state/useToggle";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form";
import FormError from "../../ui/FormError";
import Page from "../../ui/Page.tsx";
import PhoneInput from "../../ui/PhoneInput";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const { currentLanguage } = useI18n();
  const navigate = useNavigate();
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [error, setError] = useError();

  const {
    handleSubmit,
    clearErrors,
    control,
    formState: { errors },
  } = useForm<{ phone: string; agree: boolean }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
  });

  const handleSubmitForm = (data: { phone: string; agree: boolean }) => {
    submitDisabled.turnOn();
    inputDisabled.turnOn();
    setError(null);
    api
      .authStart({
        phone: data.phone,
        timezone: dayjs.tz.guess(),
        language: currentLanguage,
        termsAgreed: true,
      })
      .then((r: any) =>
        navigate("/one-time-password", {
          state: {
            phoneNumber: data.phone,
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
    <Page buffer>
      <BreadcrumbBack back />
      <h2>{t("forms.get_started")}</h2>
      <p id="phoneRequired">{t("forms.get_started_intro")}</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <PhoneInput
          className="mb-3"
          name="phone"
          control={control}
          clearErrors={clearErrors}
          label={t("forms.phone")}
          autoFocus
          required
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
        <SignupAgreement error={errors.agree?.message} control={control} />
        <FormError error={error} />
        <ButtonGroup bottom>
          <ContinueButton />
        </ButtonGroup>
      </Form>
    </Page>
  );
}

const logger = new Logger("user-auth");
