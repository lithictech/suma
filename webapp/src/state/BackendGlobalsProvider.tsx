import api from "../api";
import useAsyncFetch from "./useAsyncFetch";
import React from "react";

interface BackendGlobalsContextValue {
  supportedLocales: { items: Locale[] };
  supportedPaymentMethods: { items: string[] };
  isPaymentMethodSupported: (pm: string) => boolean;
}

export const BackendGlobalsContext = React.createContext<BackendGlobalsContextValue>(
  {} as BackendGlobalsContextValue
);

export default function BackendGlobalsProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const { state: supportedLocales } = useAsyncFetch<{ items: Locale[] }>(
    api.getSupportedLocales,
    {
      default: { items: [] },
      pickData: true,
    }
  );
  const { state: supportedPaymentMethods } = useAsyncFetch<{ items: string[] }>(
    api.getSupportedPaymentMethods,
    {
      default: { items: [] },
      pickData: true,
    }
  );

  const isPaymentMethodSupported = React.useCallback(
    (pm: string) => supportedPaymentMethods.items.includes(pm),
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
