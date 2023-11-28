import api from "../api";
import ContactListTags from "../components/ContactListTags";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { md, mdp, t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { dayjs } from "../modules/dayConfig";
import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import { extractErrorCode, useError } from "../state/useError";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function ContactListAdd() {
  const [params] = useSearchParams();
  const eventName = params.get("eventName") || "";
  const navigate = useNavigate();
  const { language } = useI18Next();
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
  const handleFormSubmit = () => {
    api
      .authContactList({
        name,
        phone,
        language,
        timezone: dayjs.tz.guess(),
        event_name: eventName,
        channel: referral,
      })
      .then(() => {
        navigate(
          eventName
            ? `/contact-list/success?eventName=${eventName}`
            : "/contact-list/success"
        );
      })
      .catch((err) => {
        setError(extractErrorCode(err));
      });
  };

  const runSetter = (name, set, value) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  const handleInputChange = (e, set) => {
    runSetter(e.target.name, set, e.target.value);
  };

  const handlePhoneChange = (e, set) => {
    runSetter(e.target.name, set, maskPhoneNumber(e.target.value, phone));
  };
  return (
    <>
      <h2 className="page-header">{t("contact_list:signup_title")}</h2>
      {mdp("contact_list:signup_intro")}
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <FormControlGroup
          className="mb-3"
          name="name"
          label={t("forms:name")}
          required
          register={register}
          errors={errors}
          value={name}
          onChange={(e) => handleInputChange(e, setName)}
        />
        <FormControlGroup
          className="mb-3"
          type="tel"
          name="phone"
          label={t("forms:phone")}
          pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
          required
          register={register}
          errors={errors}
          value={phone}
          autoComplete="tel"
          onChange={(e) => handlePhoneChange(e, setPhone)}
        />
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            name="channel"
            label={t("contact_list:referral_label")}
            required
            Input={Form.Select}
            inputClass={referral ? null : "select-noselection"}
            register={register}
            errors={errors}
            value={referral}
            onChange={(e) => handleInputChange(e, setReferral)}
          >
            <option disabled value="">
              {t("contact_list:referral_label")}
            </option>
            <option value="instagram">Instagram</option>
            {referralList.map((referral) => (
              <option key={referral.value} value={referral.value}>
                {t(referral.key)}
              </option>
            ))}
          </FormControlGroup>
        </Row>
        <FormError error={error} />
        <p className="text-secondary">
          {md("auth:unified_passive_signup_agreement", {
            buttonLabel: t("forms:submit"),
          })}
        </p>
        <FormButtons
          variant="outline-primary"
          back
          primaryProps={{ children: t("forms:submit") }}
        />
      </Form>
      <ContactListTags />
    </>
  );
}

const referralList = [
  { key: "contact_list:labels:friends_family", value: "friends_family" },
  { key: "contact_list:labels:local_community", value: "local_community" },
  { key: "contact_list:labels:suma_staff", value: "suma_staff" },
  { key: "contact_list:labels:suma_event", value: "suma_event" },
  { key: "contact_list:labels:mysuma_website", value: "mysuma_website" },
  { key: "contact_list:labels:other", value: "other" },
];
