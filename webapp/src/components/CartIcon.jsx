import loaderRing from "../assets/images/loader-ring.svg";
import clsx from "clsx";
import React from "react";

export default function CartIcon({ className, cart }) {
  const [cartLoading, setCartLoading] = React.useState(false);
  const lastHash = React.useRef(cart.cartHash);
  const [innerItemCount, setInnerItemCount] = React.useState(cart.items?.length || 0);

  let timerHandle = React.useRef(0);
  React.useEffect(() => {
    if (lastHash.current === cart.cartHash) {
      return;
    }
    setCartLoading(true);
    lastHash.current = cart.cartHash;
    timerHandle.current = window.setTimeout(() => {
      setInnerItemCount(cart.items?.length);
      setCartLoading(false);
    }, 500);
    return () => window.clearTimeout(timerHandle.current);
  }, [cart.cartHash, cart.items.length]);

  return (
    <span className={className}>
      <span className={clsx("cart-icon-text", cartLoading && "loading")}>
        <i className="bi bi-cart4 me-2"></i>
        {innerItemCount}
      </span>
      <img
        src={loaderRing}
        className={clsx(
          "cart-icon-loader start-50 translate-middle-x h-100",
          cartLoading && "loading"
        )}
        alt=""
      />
    </span>
  );
}
