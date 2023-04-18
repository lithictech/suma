import api from "../api";
import ContactListTags from "../components/ContactListTags";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { t } from "../localization";
import useI18Next from "../localization/useI18Next";
import { dayjs } from "../modules/dayConfig";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";
import { isPossiblePhoneNumber } from "react-phone-number-input";
import Input from "react-phone-number-input/input";
import "react-phone-number-input/style.css";
import { useLocation, useNavigate } from "react-router-dom";

export default function ContactListAdd() {
  const navigate = useNavigate();
  const location = useLocation();
  const { language } = useI18Next();
  const validated = useToggle(false);
  const [phoneError, setPhoneError] = useError();
  const phoneRef = React.useRef("");
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  const [error, setError] = React.useState("");
  const [name, setName] = React.useState("");
  const [phoneNumber, setPhoneNumber] = React.useState("");
  const [referral, setReferral] = React.useState("");
  const handleFormSubmit = (event) => {
    event.preventDefault();
    validated.turnOn();

    if (!phoneNumber) {
      setPhoneError("required");
      return;
    }
    if (!isPossiblePhoneNumber(phoneNumber)) {
      setError("impossible_phone_number");
      return;
    }
    api
      .authContactList({
        name: name,
        phone: phoneNumber,
        channel: referral,
        event_name: location.state.eventName,
        timezone: dayjs.tz.guess(),
        language,
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

  return (
    <>
      <h2 className="page-header">sumas contact list</h2>
      <p>
        Sign up to our contact list to be notified about future events and saving
        opportunities.
      </p>
      <Form
        noValidate
        validated={validated.isOn}
        onSubmit={handleSubmit(handleFormSubmit)}
      >
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
        <Form.Group className="mb-3" controlId="phoneInput">
          <Input
            id="phoneInput"
            ref={phoneRef}
            className="form-control"
            useNationalFormatForDefaultCountryValue={true}
            international={false}
            onChange={(value) => setPhoneNumber(value)}
            country="US"
            pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
            minLength="14"
            maxLength="14"
            placeholder={t("forms:phone")}
            value={phoneNumber}
            aria-describedby="phoneRequired"
            autoComplete="tel-national"
            required
          />
        </Form.Group>
        <FormError error={phoneError} />

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
