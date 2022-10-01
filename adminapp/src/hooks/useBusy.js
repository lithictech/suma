import React from "react";

export default function useBusy(initial) {
  const [isBusy, setIsBusy] = React.useState(initial || false);
  const busy = React.useCallback(() => setIsBusy(true), []);
  const notBusy = React.useCallback(() => setIsBusy(false), []);
  return { isBusy, setIsBusy, busy, notBusy };
}
