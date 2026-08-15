import Button from "../ui/Button";
import CartIcon from "./CartIcon";
import React from "react";

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
      variant={cart.items?.length > 0 ? "primary" : "outline"}
      className="py-1"
      size="sm"
    >
      <CartIcon cart={cart} className="d-flex flex-row position-relative" />
    </Button>
  );
}
