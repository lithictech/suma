import api from "../api";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import React from "react";

export const BackendGlobalsContext = React.createContext({});

export default function BackendGlobalsProvider({ children }) {
  const { state: supportedLocales } = useAsyncFetch(api.getSupportedLocales, {
    default: { items: [] },
    pickData: true,
  });
  const { state: supportedPaymentMethods } = useAsyncFetch(
    api.getSupportedPaymentMethods,
    {
      default: { items: [] },
      pickData: true,
    }
  );

  const isPaymentMethodSupported = React.useCallback(
    (pm) => supportedPaymentMethods.items.includes(pm),
    [supportedPaymentMethods]
  );

  return (
    <BackendGlobalsContext.Provider
      value={{
        supportedLocales,
        supportedPaymentMethods,
        isPaymentMethodSupported,
      }}
    >
      {children}
    </BackendGlobalsContext.Provider>
  );
}
