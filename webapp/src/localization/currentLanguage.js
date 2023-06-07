import { localStorageCache } from "../shared/localStorageHelper";
import useLocalStorageState from "../shared/react/useLocalStorageState";

let cachedLanguage = localStorageCache.getItem("language", "en");

export function getCurrentLanguage() {
  return cachedLanguage;
}

export function setCurrentLanguage(value) {
  cachedLanguage = value;
}

export function useCurrentLanguage() {
  const [language, setLanguage] = useLocalStorageState("language", "en");
  return [language, setLanguage];
}
