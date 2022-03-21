import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { isValidPhoneNumber } from 'react-phone-number-input';
// import { start } from "../api/auth";
import Input from 'react-phone-number-input/input'
import 'react-phone-number-input/style.css'

import Form from 'react-bootstrap/Form';
import Button from 'react-bootstrap/Button';
import Container from 'react-bootstrap/Container';
import Row from 'react-bootstrap/Row';
import Col from 'react-bootstrap/Col';

const Start = () => {
  const [phoneNumber, setPhoneNumber] = useState(undefined);
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(true);
  const [isInputDisabled, setIsInputDisabled] = useState(false);
  const navigate = useNavigate();

  const handleNumberChange = (value) => {
    setPhoneNumber(value);
    if (value && value.length === 12) {
      setIsSubmitDisabled(false);
    } else {
      setIsSubmitDisabled(true);
    }
  }

  const handleSubmit = (event) => {
    event.preventDefault();
    setIsSubmitDisabled(true);
    setIsInputDisabled(true);

    if (isValidPhoneNumber(phoneNumber) === true) {
      return navigate("/one-time-password", { state: { phoneNumber } });
      // TODO: Uncomment once api setup is done
      // start(phoneNumber).then((response) => {
      //   if (response) {
      //     return navigate("/one-time-password", { state: { phoneNumber } });
      //   }
      // }).catch((error) => {
      //     // TODO: BS warning alert
      //     console.log(error);
      // })
    }
    // TODO: BS warning alert
    console.log("BS warning alert");
    setIsSubmitDisabled(false);
    setIsInputDisabled(false);
  }
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
                disabled={isInputDisabled}
              />
              <Form.Text className="text-muted">
                To verify your identity, you are required to sign in with your phone number.{" "}
                We will send you a verification code to your phone number.
              </Form.Text>
            </Form.Group>
            <Button variant="outline-success" type="submit" disabled={isSubmitDisabled}>
              Continue
            </Button>
          </Form>
        </Col>
      </Row>
    </Container>
  );
}

export default Start;