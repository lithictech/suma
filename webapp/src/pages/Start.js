import api from "../api";
import FormError from "../components/FormError";
import { dayjs } from "../modules/dayConfig";
import { extractErrorCode, useError } from "../state/useError";
import useToggle from "../state/useToggle";
import React, { useState } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { isPossiblePhoneNumber } from "react-phone-number-input";
import Input from "react-phone-number-input/input";
import "react-phone-number-input/style.css";
import { useNavigate } from "react-router-dom";

const Start = () => {
  const [phoneNumber, setPhoneNumber] = useState("");
  const submitDisabled = useToggle(false);
  const inputDisabled = useToggle(false);
  const [error, setError] = useError();
  const navigate = useNavigate();

  const handleNumberChange = (value) => {
    setPhoneNumber(value);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
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
        timezone: dayjs.tz.guess(),
      })
      .then(() => navigate("/one-time-password", { state: { phoneNumber } }))
      .catch((err) => {
        setError(extractErrorCode(err));
        submitDisabled.turnOff();
        inputDisabled.turnOff();
      });
  };
  return (
    <Container>
      <Row>
        <Col>
          <Form onSubmit={handleSubmit}>
            <Form.Group className="mb-3" controlId="formBasicPhoneNumber">
              <Form.Label>Phone number</Form.Label>
              <Input
                style={{ display: "block" }}
                useNationalFormatForDefaultCountryValue={true}
                international={false}
                country="US"
                maxLength="14"
                placeholder="e.g. (919) 123-4567"
                onChange={handleNumberChange}
                value={phoneNumber}
                disabled={inputDisabled.isOn}
              />
              <Form.Text className="text-muted">
                To verify your identity, you are required to sign in with your phone
                number. We will send you a verification code to your phone number.
              </Form.Text>
            </Form.Group>
            <FormError error={error} />
            <Button
              variant="outline-success"
              type="submit"
              disabled={submitDisabled.isOn}
            >
              Continue
            </Button>
          </Form>
        </Col>
      </Row>
    </Container>
  );
};

export default Start;
