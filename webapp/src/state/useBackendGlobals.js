import api from "../api";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import React from "react";

export const BackendGlobalsContext = React.createContext();
export const useBackendGlobals = () => React.useContext(BackendGlobalsContext);

export function BackendGlobalsProvider({ children }) {
  const { state: supportedLocales } = useAsyncFetch(api.getSupportedLocales, {
    default: { items: [] },
    pickData: true,
  });

  return (
    <BackendGlobalsContext.Provider
      value={{
        supportedLocales,
      }}
    >
      {children}
    </BackendGlobalsContext.Provider>
  );
}
