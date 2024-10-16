import React from "react";

/**
 * Just a `React.useEffect(() => cb, [])` that is more declarative than
 * doing it in line and disabling eslint.
 * @param {function} cb
 */
export default function useUnmountEffect(cb) {
  // eslint-disable-next-line react-hooks/exhaustive-deps
  React.useEffect(() => cb, []);
}
