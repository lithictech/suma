import { guttersClass } from "../modules/constants";
import CartIcon from "./CartIcon";
import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

export default function FoodNav({ offeringId, startElement, cart }) {
  return (
    <Container className={`hstack gap-3 border-0 py-2 ${guttersClass}`}>
      {startElement && startElement}
      <Button
        href={`/cart/${offeringId}`}
        variant={clsx(cart.items?.length > 0 ? "success" : "primary")}
        className="ms-auto py-1"
        size="sm"
        as={RLink}
      >
        <CartIcon cart={cart} className="d-flex flex-row position-relative" />
      </Button>
    </Container>
  );
}
