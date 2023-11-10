import React from "react";
import loaderRing from "../assets/images/loader-ring.svg";
import clsx from "clsx";

export default function CartIcon({ className, cart }) {
  const [cartLoading, setCartLoading] = React.useState(false);
  let timerHandle = React.useRef(0);
  React.useEffect(() => {
    setCartLoading(true);
    timerHandle.current = window.setTimeout(() => setCartLoading(false), 500)
    return () => window.clearTimeout(timerHandle.current)
  }, [cart.cartHash])
  return (
    <span className={className}>
      <span className={clsx("cart-icon-text", cartLoading && 'loading')}>
      <i className="bi bi-cart4 me-2"></i>
      {cart.items?.length || 0}
        </span>
      <img
        src={loaderRing}
        className={clsx("cart-icon-loader", cartLoading && 'loading')}
        width="32"
        height="32"
        alt="cart quantity loading"
      />
    </span>
  );
}
