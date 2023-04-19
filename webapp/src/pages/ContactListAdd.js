import api from "../api";
import ContactListTags from "../components/ContactListTags";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { dayjs } from "../modules/dayConfig";
import { formatPhoneNumber } from "../modules/numberFormatter";
import { extractErrorCode, useError } from "../state/useError";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";
import { useLocation, useNavigate } from "react-router-dom";

export default function ContactListAdd() {
  const navigate = useNavigate();
  const location = useLocation();
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
        event_name: location.state.eventName,
        channel: referral,
      })
      .then(() => {
        navigate("/contact-list/success");
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

  const handleNumberChange = (e, set) => {
    runSetter(e.target.name, set, formatPhoneNumber(e.target.value, phone));
  };
  return (
    <>
      <h2 className="page-header">sumas contact list</h2>
      <p>
        Sign up to our contact list to be notified about future events and saving
        opportunities.
      </p>
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
          name="phone"
          label={t("forms:phone")}
          pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
          required
          register={register}
          errors={errors}
          value={phone}
          onChange={(e) => handleNumberChange(e, setPhone)}
          autoComplete="tel-national"
        />
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            name="channel"
            label={"How did you hear about us?"}
            required
            Input={Form.Select}
            inputClass={referral ? null : "select-noselection"}
            register={register}
            errors={errors}
            value={referral}
            onChange={(e) => handleInputChange(e, setReferral)}
          >
            <option disabled value="">
              How did you hear about us?
            </option>
            {channelList.map((referral) => (
              <option key={referral.value} value={referral.value}>
                {referral.label}
              </option>
            ))}
          </FormControlGroup>
        </Row>
        <FormError error={error} />
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

const channelList = [
  { label: "Twitter", value: "twitter" },
  { label: "Instagram", value: "instagram" },
  { label: "Friend/Family", value: "person" },
  { label: "Other", value: "other" },
];
