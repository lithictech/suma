import api from "../api";
import FormButtons from "../components/FormButtons";
import FormError from "../components/FormError";
import TopNav from "../components/TopNav";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode } from "../state/useError";
import { useUser } from "../state/useUser";
import { t } from "i18next";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useNavigate } from "react-router-dom";

function OnboardingSignup() {
  const navigate = useNavigate();
  const { setUser } = useUser();
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
    e.stopPropagation();
    if (e.currentTarget.checkValidity() === false) {
      validated.turnOn();
      return;
    }
    api
      .updateMe({
        name: name,
        address: {
          address1: address,
          address2: address2,
          city: city,
          state_or_province: state,
          postal_code: zipCode,
        },
      })
      .then((r) => {
        setUser(r.data);
        navigate("/onboarding/finish");
      })
      .catch((err) => {
        setError(extractErrorCode(err));
      });
  };

  const handleInputChange = (e, set) => set(e.target.value);

  const handleZipChange = (e) => {
    const v = e.target.value.replace(/\D/, "").slice(0, 5);
    setZipCode(v);
  };

  const { state: supportedGeographies } = useAsyncFetch(api.getSupportedGeographies, {
    default: {},
    pickData: true,
  });

  return (
    <div className="main-container">
      <TopNav />
      <Row>
        <Col>
          <h2>Enroll in Suma</h2>
          <p>
            Welcome to Suma! To get started, we will need to verify your identity. This
            makes sure you are eligible for the right programs, such as with our
            affordable housing partners.
          </p>
          <p>
            <strong>
              We will never share this information other than to verify your identity.
            </strong>
          </p>
          <Form noValidate validated={validated.isOn} onSubmit={handleFormSubmit}>
            <Form.Group className="mb-3" controlId="name">
              <Form.Label>{t("name", { ns: "forms" })}</Form.Label>
              <Form.Control
                name="name"
                value={name}
                onChange={(e) => handleInputChange(e, setName)}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address">
              <Form.Label>{t("address1", { ns: "forms" })}</Form.Label>
              <Form.Control
                type="Text"
                name="address"
                value={address}
                onChange={(e) => handleInputChange(e, setAddress)}
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address2">
              <Form.Label>{t("address2", { ns: "forms" })}</Form.Label>
              <Form.Control
                type="text"
                name="address2"
                value={address2}
                onChange={(e) => handleInputChange(e, setAddress2)}
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="cityInput">
              <Form.Label>{t("city", { ns: "forms" })}</Form.Label>
              <Form.Control
                type="text"
                name="city"
                value={city}
                onChange={(e) => handleInputChange(e, setCity)}
                required
              />
            </Form.Group>
            <Row className="mb-3">
              <Form.Group as={Col} controlId="stateInput">
                <Form.Label>{t("state", { ns: "forms" })}</Form.Label>
                <Form.Select
                  value={state}
                  onChange={(e) => handleInputChange(e, setState)}
                  required
                >
                  <option disabled value="">
                    Choose state...
                  </option>
                  {!!supportedGeographies.provinces &&
                    supportedGeographies.provinces.map((state) => (
                      <option key={state.value} value={state.value}>
                        {state.label}
                      </option>
                    ))}
                </Form.Select>
              </Form.Group>
              <Form.Group as={Col} controlId="zipInput">
                <Form.Label>{t("zip", { ns: "forms" })}</Form.Label>
                <Form.Control
                  type="text"
                  pattern="^[0-9]{5}(?:-[0-9]{4})?$"
                  minLength="5"
                  maxLength="10"
                  value={zipCode}
                  onChange={handleZipChange}
                  required
                />
              </Form.Group>
            </Row>
            <FormError error={error} />
            <FormButtons variant="success" back primaryProps={{ children: "Submit" }} />
          </Form>
        </Col>
      </Row>
    </div>
  );
}

export default OnboardingSignup;
