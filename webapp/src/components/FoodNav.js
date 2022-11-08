import CartIcon from "./CartIcon";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function FoodNav({ startElement, cart }) {
  if (startElement) {
    return (
      <Container className="hstack gap-3 border-start border-end py-2">
        {startElement && startElement}
        <Button variant="success" className="ms-auto py-1">
          <CartIcon cart={cart} />
        </Button>
      </Container>
    );
  }
  return (
    <Button variant="success" className="py-1 mt-2">
      <CartIcon cart={cart} />
    </Button>
  );
}
