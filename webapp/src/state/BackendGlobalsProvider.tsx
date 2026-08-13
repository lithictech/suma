import api from "../api";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import React from "react";

interface BackendGlobalsContextValue {
  supportedLocales: { items: any[] };
  supportedPaymentMethods: { items: any[] };
  isPaymentMethodSupported: (pm: any) => boolean;
}

export const BackendGlobalsContext = React.createContext<BackendGlobalsContextValue>(
  {} as BackendGlobalsContextValue
);

export default function BackendGlobalsProvider({
  children,
}: {
  children: React.ReactNode;
}) {
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
    (pm: any) => supportedPaymentMethods.items.includes(pm),
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
