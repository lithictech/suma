import useToggle from "../shared/react/useToggle";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";

// import { useNavigate } from "react-router";

function OnboardingSignup() {
  // const navigate = useNavigate();
  const { t } = i18next;
  const validated = useToggle(false);
  const [states, setStates] = React.useState([]);

  const handleFormSubmit = (event) => {
    const form = event.currentTarget;
    if (form.checkValidity() === false) {
      event.preventDefault();
      event.stopPropagation();
    }

    validated.turnOn();
    // TODO: should call onboarding api then navigate to dashboard
    // navigate("/dashboard");
  };

  React.useEffect(() => {
    Promise.resolve({ states: [{ value: "OR", label: "Oregon" }] }).then((r) =>
      setStates(r.states)
    );
  }, []);
  return (
    <div className="main-container">
      <Row>
        <Col>
          <h2>Member Onboarding</h2>
          <p className="text-muted small">
            To join our platform, you are required to enter your address to verify your
            eligibility for membership.
          </p>
          <Form noValidate validated={validated.isOn} onSubmit={handleFormSubmit}>
            <Form.Group className="mb-3" controlId="name">
              <Form.Label>{t("label_name", { ns: "forms" })}</Form.Label>
              <Form.Control
                // name="name"
                placeholder="Full Name"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address1">
              <Form.Label>{t("label_address", { number: "1", ns: "forms" })}</Form.Label>
              <Form.Control
                // name="address"
                placeholder="e.g. 123 Main Street"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address2">
              <Form.Label>{t("label_address", { number: "2", ns: "forms" })}</Form.Label>
              <Form.Control
              // name="address2"
              />
            </Form.Group>
            <Row className="mb-3">
              <Form.Group as={Col} md="6" controlId="cityInput">
                <Form.Label>{t("label_city", { ns: "forms" })}</Form.Label>
                <Form.Control type="text" placeholder="City" required />
              </Form.Group>
              <Form.Group as={Col} controlId="stateInput">
                <Form.Label>{t("label_state", { ns: "forms" })}</Form.Label>
                <Form.Select defaultValue="" required>
                  <option disabled value="">
                    Choose state...
                  </option>
                  {states.map((state, i) => {
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
                <Form.Control type="text" placeholder="Zip" required />
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
