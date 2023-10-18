import { localStorageCache } from "../localStorageHelper";
import React from "react";

export default function useLocalStorageState(key, defaultVal) {
  const [state, setStateInner] = React.useState(
    localStorageCache.getItem(key, defaultVal)
  );

  const setState = React.useCallback(
    (x) => {
      setStateInner(x);
      localStorageCache.setItem(key, x);
    },
    [key]
  );

  return [state, setState];
}
