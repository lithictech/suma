import { localStorageCache } from "../shared/localStorageHelper";
import useLocalStorageState from "../shared/react/useLocalStorageState";
import React from "react";

let cachedLanguage = localStorageCache.getItem("language", "en");

/**
 * Return the current language. Use only when outside of React;
 * inside of React use the useCurrentLanguage hook.
 */
export function getCurrentLanguage(): string {
  return cachedLanguage;
}

export function setCurrentLanguage(value: string) {
  cachedLanguage = value;
}

export function useCurrentLanguage(): [string, (value: string) => void] {
  const [language, setLanguageInner] = useLocalStorageState("language", cachedLanguage);
  const setLanguage = React.useCallback(
    (value: string) => {
      cachedLanguage = value;
      setLanguageInner(value);
    },
    [setLanguageInner]
  );
  return [language, setLanguage];
}
