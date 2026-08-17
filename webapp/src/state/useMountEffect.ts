import React from "react";

/**
 * Just a `React.useEffect(cb, [])` that is more declarative than
 * doing it in line and disabling eslint.
 */
export default function useMountEffect(cb: React.EffectCallback) {
  // eslint-disable-next-line react-hooks/exhaustive-deps
  React.useEffect(cb, []);
}
