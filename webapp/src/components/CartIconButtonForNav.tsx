import CartIconButton from "./CartIconButton";
import React from "react";

/**
 * Wraps CartIconButton in a component that can be used as a stickyNavAddon
 * in a PageLayout.
 */
export default function CartIconButtonForNav(props: {
  offeringId: number | string;
  cart: Cart;
}) {
  return (
    <div
      className="position-absolute p-2 bg-light"
      style={{ right: 0, borderBottomLeftRadius: 24 }}
    >
      <CartIconButton {...props} />
    </div>
  );
}
