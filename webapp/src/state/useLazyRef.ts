import React from "react";

export default function useLazyRef<T>(factory: () => T): T {
  const ref = React.useRef<T | Sentinel>(SENTINEL);
  if (ref.current === SENTINEL) {
    ref.current = factory();
  }
  return ref.current;
}

const SENTINEL: unique symbol = Symbol("sentinel");
type Sentinel = typeof SENTINEL;
