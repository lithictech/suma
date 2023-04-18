import ContactListTags from "../components/ContactListTags";
import RLink from "../components/RLink";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function ContactListSuccess() {
  return (
    <Container>
      <div className="text-center">
        <p>Thank you for signing up!</p>
        <div className="button-stack">
          <Button
            href="/contact-list"
            variant="outline-primary"
            as={RLink}
            className="w-75"
          >
            Sign up again
          </Button>
          <ContactListTags />
        </div>
      </div>
    </Container>
  );
}
