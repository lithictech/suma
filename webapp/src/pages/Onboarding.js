import React, { useState } from "react";
import Button from "react-bootstrap/Button";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";

const Onboarding = () => {
  const [isSubmitDisabled, setIsSubmitDisabled] = useState(false);

  const handleFormSubmit = (event) => {
    event.preventDefault();
    setIsSubmitDisabled(true);
    // navigate to tutorial after submittion
    console.log("Navigate to tutorial");
  };
  return (
    <Container>
      <Row className="justify-content-center">
        <Col>
          <h2>Member Onboarding</h2>
          <Form onSubmit={handleFormSubmit}>
            <Form.Group className="mb-3" controlId="formBasicPhoneNumber">
              <Form.Label>Name</Form.Label>
              <Form.Control
                // name="name"
                placeholder="Full Name"
              />
            </Form.Group>
            <Form.Group className="mb-3" controlId="formBasicPhoneNumber">
              <Form.Label>Full Address</Form.Label>
              <Form.Control
                // name="address"
                placeholder="e.g. 123 Main Street, Durham, North Carolina 27701"
              />
              <Form.Text className="text-muted">
                This address will be used to verify your eligibility for membership.
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
};

export default Onboarding;
