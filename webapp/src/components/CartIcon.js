import React from "react";

export default function CartIcon({ className, cart }) {
  return (
    <span className={className}>
      <i className="bi bi-cart4 me-2"></i>
      {cart.items?.length || 0}
    </span>
  );
}
