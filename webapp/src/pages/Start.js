import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import React, { useState } from "react";
import Form from "react-bootstrap/Form";
import { isPossiblePhoneNumber } from "react-phone-number-input";
import Input from "react-phone-number-input/input";
import "react-phone-number-input/style.css";
import { useNavigate } from "react-router-dom";

export default function Start() {
  const [phoneNumber, setPhoneNumber] = useState("");
  const validated = useToggle(false);
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [error, setError] = useError();
  const navigate = useNavigate();
  const phoneRef = React.useRef();

  const handleNumberChange = (value) => {
    setPhoneNumber(value);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    validated.turnOn();
    phoneRef.current.focus();

    if (!phoneNumber) {
      setError("required");
      return;
    }
    if (!isPossiblePhoneNumber(phoneNumber)) {
      setError("impossible_phone_number");
      return;
    }
    submitDisabled.turnOn();
    inputDisabled.turnOn();

    api
      .authStart({
        phone: phoneNumber,
        timezone: dayjs.tz.guess(),
      })
      .then((r) =>
        navigate("/one-time-password", {
          state: { phoneNumber, requiresTermsAgreement: r.data.requiresTermsAgreement },
        })
      )
      .catch((err) => {
        setError(extractErrorCode(err));
        validated.turnOff();
        submitDisabled.turnOff();
        inputDisabled.turnOff();
        phoneRef.current.classList.add("is-invalid");
      });
  };
  return (
    <>
      <h2>{t("forms:get_started")}</h2>
      <p id="phoneRequired">{t("forms:get_started_intro")}</p>
      <Form noValidate validated={validated.isOn} onSubmit={handleSubmit}>
        <Form.Group className="mb-3" controlId="phoneInput">
          <Input
            id="phoneInput"
            ref={phoneRef}
            className="form-control"
            useNationalFormatForDefaultCountryValue={true}
            international={false}
            onChange={handleNumberChange}
            country="US"
            pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
            minLength="14"
            maxLength="14"
            placeholder={t("forms:phone")}
            value={phoneNumber}
            disabled={inputDisabled.isOn}
            aria-describedby="phoneRequired"
            autoComplete="tel-national"
            autoFocus
            required
          />
          <FormError error={error} />
        </Form.Group>
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
