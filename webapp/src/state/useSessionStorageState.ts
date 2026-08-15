import { sessionStorageCache } from "../modules/localStorageHelper";
import React from "react";

export default function useSessionStorageState<T = any>(
  key: string,
  defaultVal?: T
): [T, (x: T) => void] {
  const [state, setStateInner] = React.useState(
    sessionStorageCache.getItem(key, defaultVal)
  );

  const setState = React.useCallback(
    (x: T) => {
      setStateInner(x);
      sessionStorageCache.setItem(key, x);
    },
    [key]
  );

  return [state, setState];
}
