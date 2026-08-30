import api from "../../api";
import SignupAgreement from "../../components/SignupAgreement";
import { MdLink } from "../../components/SumaMarkdown";
import { t } from "../../localization";
import useI18n from "../../localization/useI18n";
import { dayjs } from "../../modules/dayConfig";
import { AppError, extractAppErrorAny } from "../../modules/feedback.ts";
import { Logger } from "../../modules/logger";
import useNavigate from "../../routing/useNavigate";
import useToggle from "../../state/useToggle";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form";
import FormFeedback from "../../ui/FormFeedback";
import Page from "../../ui/Page.tsx";
import PhoneInput from "../../ui/PhoneInput";
import React from "react";
import { useForm } from "react-hook-form";

export default function Start() {
  const { currentLanguage } = useI18n();
  const navigate = useNavigate();
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [error, setError] = React.useState<AppError | null>();

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
      .catch((err) => {
        const appErr = extractAppErrorAny(err);
        setError(appErr);
        submitDisabled.turnOff();
        inputDisabled.turnOff();
        if (appErr.code === "auth_conflict") {
          logger.error("Unexpected auth conflict");
          window.location.reload();
        }
      });
  };
  return (
    <Page>
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
        <FormFeedback feedback={error} />
        <ButtonGroup bottom>
          <ContinueButton />
        </ButtonGroup>
      </Form>
    </Page>
  );
}

const logger = new Logger("user-auth");
