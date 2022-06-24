import FormButtons from "../components/FormButtons";
import React from "react";
import Container from "react-bootstrap/Container";
import { useNavigate } from "react-router-dom";

const OnboardingFinish = () => {
  const navigate = useNavigate();

  const handleSubmit = (e) => {
    e.preventDefault();
    navigate("/dashboard");
  };
  return (
    <Container>
      <p>
        Thanks! Our team will check things out and be in touch with any questions, or as
        soon as you&rsquo;re verified.
      </p>
      <p>Verification usually happens within 1-2 business days.</p>
      <p>
        In the meantime, you can learn more about the application and see what is
        available.
      </p>
      <FormButtons
        variant="success"
        primaryProps={{ children: "Okay!", onClick: handleSubmit }}
      />
    </Container>
  );
};

export default OnboardingFinish;
