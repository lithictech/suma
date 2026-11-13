import SignupAgreement from "../../components/SignupAgreement";
import { MdLink } from "../../components/SumaMarkdown";
import { t } from "../../localization";
import useI18n from "../../localization/useI18n";
import { dayjs } from "../../modules/dayConfig";
import { AppError, extractAppErrorAny } from "../../modules/feedback.ts";
import { Logger } from "../../modules/logger";
import useNavigate from "../../routing/useNavigate";
import useScreenLoader from "../../state/useScreenLoader.ts";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form";
import FormFeedback from "../../ui/FormFeedback";
import Page from "../../ui/Page.tsx";
import PhoneInput from "../../ui/PhoneInput";
import TextHeader from "../../ui/TextHeader.tsx";
import { AxiosRequestConfig, AxiosResponse } from "axios";
import React from "react";
import { useForm } from "react-hook-form";

export interface StartApiCalls {
  authStart: (
    data: {
      phone: string;
      timezone: string;
      language: string;
      termsAgreed: boolean;
    },
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<AuthFlowMember>>;
}

export interface StartProps {
  apiCalls: StartApiCalls;
}

export default function Start({ apiCalls }: StartProps) {
  const { currentLanguage } = useI18n();
  const navigate = useNavigate();
  const [error, setError] = React.useState<AppError | null>();
  const screenLoader = useScreenLoader();

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
    screenLoader.turnOn();
    setError(null);
    apiCalls
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
        screenLoader.turnOff();
        if (appErr.code === "auth_conflict") {
          logger.error("Unexpected auth conflict");
          window.location.reload();
        }
      });
  };
  return (
    <Page>
      <TextHeader
        title={t("forms.get_started")}
        subtitle={<p id="phoneRequired">{t("forms.get_started_intro")}</p>}
      />
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <PhoneInput
          name="phone"
          control={control}
          clearErrors={clearErrors}
          label={t("forms.phone")}
          autoFocus
          required
        />
        <p className="color-text-muted font-size-body-md">
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
