import { sessionStorageCache } from "../localStorageHelper";
import React from "react";

export default function useSessionStorageState(key, defaultVal) {
  const [state, setStateInner] = React.useState(
    sessionStorageCache.getItem(key, defaultVal)
  );

  const setState = React.useCallback(
    (x) => {
      setStateInner(x);
      sessionStorageCache.setItem(key, x);
    },
    [key]
  );

  return [state, setState];
}
