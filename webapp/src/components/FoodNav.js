import CartIcon from "./CartIcon";
import RLink from "./RLink";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function FoodNav({ offeringId, startElement, cart }) {
  if (startElement) {
    return (
      <Container className="hstack gap-3 border-0 py-2">
        {startElement && startElement}
        <Button
          href={`/cart/${offeringId}`}
          variant="success"
          className="ms-auto py-1"
          as={RLink}
        >
          <CartIcon cart={cart} className="d-flex flex-row" />
        </Button>
      </Container>
    );
  }
  return (
    <Button
      href={`/cart/${offeringId}`}
      variant="success"
      className="py-1 mt-2"
      as={RLink}
    >
      <CartIcon cart={cart} />
    </Button>
  );
}
