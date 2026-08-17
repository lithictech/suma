import api from "../api";
import ContactListTags from "../components/ContactListTags";
import FormControlGroup from "../components/FormControlGroup";
import PageHeading from "../components/PageHeading";
import { t } from "../localization";
import useI18n from "../localization/useI18n";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import { extractErrorCode, useError } from "../state/useError";
import Col from "../ui/Col";
import Form from "../ui/Form";
import FormButtons from "../ui/FormButtons";
import FormError from "../ui/FormError";
import FormSelect from "../ui/FormSelect";
import Row from "../ui/Row";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function ContactListAdd() {
  const [params] = useSearchParams();
  const eventName = params.get("eventName") || "";
  const navigate = useNavigate();
  const { currentLanguage } = useI18n();
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  const [error, setError] = useError();
  const [name, setName] = React.useState("");
  const [phone, setPhone] = React.useState("");
  const [referral, setReferral] = React.useState("");
  const [organizationName] = React.useState("");
  const handleFormSubmit = () => {
    api
      .authContactList({
        name,
        phone,
        language: currentLanguage,
        timezone: dayjs.tz.guess(),
        campaign: eventName,
        source: referral,
        medium: "event",
        organizationName,
      })
      .then(() => {
        navigate(
          eventName
            ? `/contact-list/success?eventName=${eventName}`
            : "/contact-list/success"
        );
      })
      .catch((err: any) => {
        setError(extractErrorCode(err));
      });
  };

  const runSetter = (name: string, set: (value: string) => void, value: string) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    set: (value: string) => void
  ) => {
    runSetter(e.target.name, set, e.target.value);
  };

  const handlePhoneChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    set: (value: string) => void
  ) => {
    runSetter(e.target.name, set, maskPhoneNumber(e.target.value));
  };

  return (
    <>
      <PageHeading>{t("contact_list.signup_title")}</PageHeading>
      <p>{t("contact_list.signup_intro")}</p>
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <FormControlGroup
          className="mb-3"
          name="name"
          label={t("forms.name")}
          required
          register={register}
          errors={errors}
          value={name}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleInputChange(e, setName)
          }
        />
        <FormControlGroup
          className="mb-3"
          type="tel"
          name="phone"
          label={t("forms.phone")}
          pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
          required
          register={register}
          errors={errors}
          value={phone}
          autoComplete="tel"
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handlePhoneChange(e, setPhone)
          }
        />
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            name="channel"
            label={t("contact_list.referral_label")}
            required
            Input={FormSelect}
            inputClass={referral ? null : "select-noselection"}
            register={register}
            errors={errors}
            value={referral}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              handleInputChange(e as any, setReferral)
            }
          >
            <option disabled value="">
              {t("contact_list.referral_label")}
            </option>
            <option value="instagram">Instagram</option>
            {referralList.map((referral) => (
              <option key={referral.value} value={referral.value}>
                {t(referral.key)}
              </option>
            ))}
          </FormControlGroup>
        </Row>
        {/*<div className="mb-3">*/}
        {/*  <OrganizationInputDropdown*/}
        {/*    organizationName={organizationName}*/}
        {/*    onOrganizationNameChange={(v: string) =>*/}
        {/*      runSetter("organizationName", setOrganizationName, v)*/}
        {/*    }*/}
        {/*    register={register}*/}
        {/*    errors={errors}*/}
        {/*  />*/}
        {/*</div>*/}
        {/*<Controller
        name="organizationName"
        control={control}
        rules={{
          required: "Email is required",
          pattern: {
            value: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
            message: "Enter a valid email",
          },
        }}
        render={({ field, fieldState }) => (
          <OrganizationInputDropdown
            organizationName={field.value}
            onOrganizationNameChange={field.onChange}
            error={fieldState.error?.message}
          />
        )}
      />*/}
        {/*<SignupAgreement register={register} errors={errors} />*/}
        <FormError error={error} />
        <FormButtons
          variant="outline"
          back
          primaryProps={{ children: t("forms.submit") }}
        />
      </Form>
      <ContactListTags />
    </>
  );
}

const referralList = [
  { key: "contact_list.labels.friends_family", value: "friends_family" },
  { key: "contact_list.labels.local_community", value: "local_community" },
  { key: "contact_list.labels.suma_staff", value: "suma_staff" },
  { key: "contact_list.labels.suma_event", value: "suma_event" },
  { key: "contact_list.labels.mysuma_website", value: "mysuma_website" },
  { key: "contact_list.labels.other", value: "other" },
];
