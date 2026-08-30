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
  const { state: supportedLocales } = useAsyncFetch<UnboundedApiCollection<Locale>>(
    api.getSupportedLocales,
    { default: { items: [] } }
  );
  const { state: supportedPaymentMethods } = useAsyncFetch<
    UnboundedApiCollection<string>
  >(api.getSupportedPaymentMethods, { default: { items: [] } });

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
