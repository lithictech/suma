import React from "react";

/**
 * Remove this with React 18.
 */
export default function useId(providedId) {
  const idRef = React.useRef("");
  if (providedId) {
    return providedId;
  }
  if (!idRef.current) {
    lastId += 1;
    idRef.current = `id-${lastId}`;
  }
  return idRef.current;
}

let lastId = 0;
