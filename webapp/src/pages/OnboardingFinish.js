import React from "react";
import Button from "react-bootstrap/Button";

export default function OnboardingFinish() {
  return (
    <>
      <p>
        Thanks! Our team will check things out and be in touch with any questions, or as
        soon as you&rsquo;re verified.
      </p>
      <p>Verification usually happens within 1-2 business days.</p>
      <p>
        In the meantime, you can learn more about the application and see what is
        available.
      </p>
      <div className="button-stack">
        <Button href="/dashboard" variant="outline-primary" className="mt-3">
          Okay!
        </Button>
      </div>
    </>
  );
}
