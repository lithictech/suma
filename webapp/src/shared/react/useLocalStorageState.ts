import { localStorageCache } from "../localStorageHelper";
import React from "react";

export default function useLocalStorageState<T>(
  key: string,
  defaultVal: T
): [T, (x: T) => void] {
  const [state, setStateInner] = React.useState(
    localStorageCache.getItem(key, defaultVal)
  );

  const setState = React.useCallback(
    (x: T) => {
      setStateInner(x);
      localStorageCache.setItem(key, x);
    },
    [key]
  );

  return [state, setState];
}
