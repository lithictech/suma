import React from "react";

/**
 * Just a `React.useEffect(cb, [])` that does not fire unless in development mode.
 * @param cb
 * @param {Array=} deps Dependency list. If not given, use empty list.
 * @param {boolean=} once If true, fire just once, even in strict mode.
 */
export default function useDebugEffect(cb, { deps, once } = {}) {
  const calledRef = React.useRef(false);
  React.useEffect(() => {
    if (process.env.NODE_ENV !== "development") {
      return;
    }
    if (once && calledRef.current) {
      return;
    }
    cb();
    calledRef.current = true;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps || []);
}
