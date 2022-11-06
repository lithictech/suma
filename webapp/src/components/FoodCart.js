import React from "react";
import Button from "react-bootstrap/Button";
import Container from "react-bootstrap/Container";

/**
 * Initially a cart button with quantity but can be returned as a nav or inline node
 * @param {boolean} inline If true, return cart icon and quantity inline.
 * @param {JSX.Element} startElement Element that appears on the left side to the horizontal stack.
 *   Takes precedence over inline
 * @param {Array} cartItems Array of cart items.
 * @param {string} className Classes for the the inner-most element.
 */
export default function FoodCart({ inline, startElement, cartItems, className }) {
  // TODO: figure out where we should hook up the cart API
  let node;
  const cartAmount = cartItems?.length || 0;
  const InlineCart = () => {
    return (
      <span className={className}>
        <i className="bi bi-cart4 me-2"></i>
        {cartAmount}
      </span>
    );
  };
  if (startElement) {
    node = (
      <Container className="hstack gap-3 border-start border-end py-2">
        {startElement && startElement}
        <Button variant="success" className="ms-auto py-1">
          <InlineCart />
        </Button>
      </Container>
    );
  } else if (inline) {
    node = <InlineCart />;
  } else {
    node = (
      <Button variant="success" className="py-1 mt-2">
        <InlineCart />
      </Button>
    );
  }
  return node;
}
