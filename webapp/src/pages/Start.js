import api from "../api";
import FormError from "../components/FormError";
import { extractErrorCode, useError } from "../state/useError";
import useToggle from "../state/useToggle";
import React, { useState } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { isPossiblePhoneNumber } from "react-phone-number-input";
import Input from "react-phone-number-input/input";
import "react-phone-number-input/style.css";
import { useNavigate } from "react-router-dom";

const Start = () => {
  const [phoneNumber, setPhoneNumber] = useState("");
  const validated = useToggle(false);
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [error, setError] = useError();
  const navigate = useNavigate();

  const handleNumberChange = (value) => {
    setPhoneNumber(value);
  };

  const handleSubmit = (event) => {
    event.preventDefault();

    const form = event.currentTarget;
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    }

    validated.turnOn();
    setError();
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
        timezone: "America/New_York",
      })
      .then(() => navigate("/one-time-password", { state: { phoneNumber } }))
      .catch((err) => {
        setError(extractErrorCode(err));
        // validated.turnOff();
        submitDisabled.turnOff();
        inputDisabled.turnOff();
      });
  };
  return (
    <div className="mainContainer">
      <Row>
        <Col>
          <h2>Verification</h2>
          <Form noValidate validated={validated.isOn} onSubmit={handleSubmit}>
            <Form.Group className="mb-3" controlId="formBasicPhoneNumber">
              <Form.Label>Phone number</Form.Label>
              <Input
                className="form-control"
                useNationalFormatForDefaultCountryValue={true}
                international={false}
                onChange={handleNumberChange}
                country="US"
                pattern="\(?\d{3}\)?[- ]?\d{3}[- ]?\d{4}"
                minLength="14"
                maxLength="14"
                placeholder="Enter your number"
                value={phoneNumber}
                disabled={inputDisabled.isOn}
                required
              />
              <FormError error={error} />
              <Form.Text className="text-muted">
                To verify your identity, you are required to sign in with your phone
                number. We will send you a verification code to your phone number.
              </Form.Text>
            </Form.Group>
            <Button
              variant="success"
              type="submit"
              disabled={submitDisabled.isOn}
            >
              Continue
            </Button>
          </Form>
        </Col>
      </Row>
    </div>
  );
};

export default Start;
