import CartIcon from "./CartIcon";
import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

interface CartIconButtonProps {
  offeringId: number | string;
  cart: Cart;
}

/**
 * Render CartIcon within a button that can navigate to its cart page,
 * changes color based on contents, etc.
 */
export default function CartIconButton({ offeringId, cart }: CartIconButtonProps) {
  return (
    <Button
      href={`/cart/${offeringId}`}
      variant={clsx(cart.items?.length > 0 ? "success" : "primary")}
      className="py-1"
      size="sm"
      as={RLink}
    >
      <CartIcon cart={cart} className="d-flex flex-row position-relative" />
    </Button>
  );
}
