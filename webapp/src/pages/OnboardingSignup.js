import api from "../api";
import FormError from "../components/FormError";
import TopNav from "../components/TopNav";
import useToggle from "../shared/react/useToggle";
import useAsyncFetch from "../state/useAsyncFetch";
import { extractErrorCode } from "../state/useError";
import { t } from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useNavigate } from "react-router-dom";

function OnboardingSignup() {
  const navigate = useNavigate();
  const validated = useToggle(false);
  const [error, setError] = React.useState("");
  const [name, setName] = React.useState("");
  const [address, setAddress] = React.useState("");
  const [address2, setAddress2] = React.useState("");
  const [city, setCity] = React.useState("");
  const [state, setState] = React.useState("");
  const [zipCode, setZipCode] = React.useState("");
  const handleFormSubmit = (e) => {
    e.preventDefault();
    if (e.currentTarget.checkValidity() === false) {
      e.preventDefault();
      e.stopPropagation();
      validated.turnOn();
      return;
    }
    api
      .updateMe({
        name: name,
        address: {
          address1: address,
          city: city,
          state_or_province: state,
          postal_code: zipCode,
        },
      })
      .then(() => {
        navigate("/dashboard");
      })
      .catch((err) => {
        setError(extractErrorCode(err));
      });
  };

  const handleInputChange = (e, set) => set(e.target.value);

  const { state: meta } = useAsyncFetch(api.getMeta, {
    default: {},
    pickData: true,
  });

  return (
    <div className="main-container">
      <TopNav />
      <Row>
        <Col>
          <h2>Member Onboarding</h2>
          <p className="text-muted small">
            To join our platform, you are required to enter your name and address to
            verify your eligibility for membership.
          </p>
          <FormError error={error} />
          <Form noValidate validated={validated.isOn} onSubmit={handleFormSubmit}>
            <Form.Group className="mb-3" controlId="name">
              <Form.Label>{t("label_name", { ns: "forms" })}</Form.Label>
              <Form.Control
                name="name"
                placeholder="Full Name"
                value={name}
                onChange={(e) => handleInputChange(e, setName)}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address">
              <Form.Label>{t("label_address", { number: "1", ns: "forms" })}</Form.Label>
              <Form.Control
                type="Text"
                name="address"
                value={address}
                placeholder="e.g. 123 Main Street"
                onChange={(e) => handleInputChange(e, setAddress)}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address2">
              <Form.Label>{t("label_address", { number: "2", ns: "forms" })}</Form.Label>
              <Form.Control
                type="text"
                name="address2"
                value={address2}
                onChange={(e) => handleInputChange(e, setAddress2)}
              />
            </Form.Group>
            <Row className="mb-3">
              <Form.Group as={Col} md="6" controlId="cityInput">
                <Form.Label>{t("label_city", { ns: "forms" })}</Form.Label>
                <Form.Control
                  type="text"
                  name="city"
                  value={city}
                  placeholder="City"
                  onChange={(e) => handleInputChange(e, setCity)}
                  required
                />
              </Form.Group>
              <Form.Group as={Col} controlId="stateInput">
                <Form.Label>{t("label_state", { ns: "forms" })}</Form.Label>
                <Form.Select
                  value={state}
                  onChange={(e) => handleInputChange(e, setState)}
                  required
                >
                  <option disabled value="">
                    Choose state...
                  </option>
                  {!!meta.provinces &&
                    meta.provinces.map((state, i) => {
                      return (
                        <option key={i} value={state.value}>
                          {state.label}
                        </option>
                      );
                    })}
                </Form.Select>
              </Form.Group>
              <Form.Group as={Col} md="3" controlId="zipInput">
                <Form.Label>{t("label_zip", { ns: "forms" })}</Form.Label>
                <Form.Control
                  type="text"
                  placeholder="Zip"
                  pattern="^[0-9]{5}(?:-[0-9]{4})?$"
                  minLength="5"
                  maxLength="10"
                  value={zipCode}
                  onChange={(e) => handleInputChange(e, setZipCode)}
                  required
                />
              </Form.Group>
            </Row>
            <Button variant="success" type="submit">
              Complete Onboarding
            </Button>
          </Form>
        </Col>
      </Row>
    </div>
  );
}

export default OnboardingSignup;
