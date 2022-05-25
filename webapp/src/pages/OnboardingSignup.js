import useToggle from "../shared/react/useToggle";
import React from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";

// import { useNavigate } from "react-router";

function OnboardingSignup() {
  // const navigate = useNavigate();
  const validated = useToggle(false);

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
              <Form.Label>Name</Form.Label>
              <Form.Control
                // name="name"
                placeholder="Full Name"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address1">
              <Form.Label>Address 1</Form.Label>
              <Form.Control
                // name="address"
                placeholder="e.g. 123 Main Street"
                required
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="address2">
              <Form.Label>Address 2</Form.Label>
              <Form.Control
              // name="address2"
              />
            </Form.Group>
            <Row className="mb-3">
              <Form.Group as={Col} md="6" controlId="cityInput">
                <Form.Label>City</Form.Label>
                <Form.Control type="text" placeholder="City" required />
              </Form.Group>
              <Form.Group as={Col} controlId="stateInput">
                <Form.Label>State</Form.Label>
                <Form.Select defaultValue="" required>
                  <option disabled value="">
                    Choose state...
                  </option>
                  <option value="AL">Alabama</option>
                  <option value="AK">Alaska</option>
                  <option value="AZ">Arizona</option>
                  <option value="AR">Arkansas</option>
                  <option value="CA">California</option>
                  <option value="CO">Colorado</option>
                  <option value="CT">Connecticut</option>
                  <option value="DE">Delaware</option>
                  <option value="DC">District Of Columbia</option>
                  <option value="FL">Florida</option>
                  <option value="GA">Georgia</option>
                  <option value="HI">Hawaii</option>
                  <option value="ID">Idaho</option>
                  <option value="IL">Illinois</option>
                  <option value="IN">Indiana</option>
                  <option value="IA">Iowa</option>
                  <option value="KS">Kansas</option>
                  <option value="KY">Kentucky</option>
                  <option value="LA">Louisiana</option>
                  <option value="ME">Maine</option>
                  <option value="MD">Maryland</option>
                  <option value="MA">Massachusetts</option>
                  <option value="MI">Michigan</option>
                  <option value="MN">Minnesota</option>
                  <option value="MS">Mississippi</option>
                  <option value="MO">Missouri</option>
                  <option value="MT">Montana</option>
                  <option value="NE">Nebraska</option>
                  <option value="NV">Nevada</option>
                  <option value="NH">New Hampshire</option>
                  <option value="NJ">New Jersey</option>
                  <option value="NM">New Mexico</option>
                  <option value="NY">New York</option>
                  <option value="NC">North Carolina</option>
                  <option value="ND">North Dakota</option>
                  <option value="OH">Ohio</option>
                  <option value="OK">Oklahoma</option>
                  <option value="OR">Oregon</option>
                  <option value="PA">Pennsylvania</option>
                  <option value="RI">Rhode Island</option>
                  <option value="SC">South Carolina</option>
                  <option value="SD">South Dakota</option>
                  <option value="TN">Tennessee</option>
                  <option value="TX">Texas</option>
                  <option value="UT">Utah</option>
                  <option value="VT">Vermont</option>
                  <option value="VA">Virginia</option>
                  <option value="WA">Washington</option>
                  <option value="WV">West Virginia</option>
                  <option value="WI">Wisconsin</option>
                  <option value="WY">Wyoming</option>
                </Form.Select>
              </Form.Group>
              <Form.Group as={Col} md="3" controlId="zipInput">
                <Form.Label>Zip</Form.Label>
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
