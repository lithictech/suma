import api from "../api";
import useAsyncFetch from "./useAsyncFetch";
import React from "react";

interface BackendGlobalsContextValue {
  supportedLocales: UnboundedApiCollection<Locale>;
  supportedPaymentMethods: UnboundedApiCollection<PaymentMethodType>;
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
    UnboundedApiCollection<PaymentMethodType>
  >(api.getSupportedPaymentMethods, { default: { items: [] } });

  return (
    <BackendGlobalsContext.Provider
      value={{
        supportedLocales,
        supportedPaymentMethods,
      }}
    >
      {children}
    </BackendGlobalsContext.Provider>
  );
}
