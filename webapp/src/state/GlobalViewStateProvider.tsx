import React from "react";

interface GlobalViewStateContextValue {
  topNav: HTMLElement | null;
  setTopNav: (el: HTMLElement | null) => void;
  appNav: HTMLElement | null;
  setAppNav: (el: HTMLElement | null) => void;
}

export const GlobalViewStateContext = React.createContext<GlobalViewStateContextValue>(
  {} as GlobalViewStateContextValue
);

export default function GlobalViewStateProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [topNav, setTopNav] = React.useState<HTMLElement | null>(null);
  const [appNav, setAppNav] = React.useState<HTMLElement | null>(null);
  const value = React.useMemo(
    () => ({ topNav, setTopNav, appNav, setAppNav }),
    [appNav, topNav]
  );
  return (
    <GlobalViewStateContext.Provider value={value}>
      {children}
    </GlobalViewStateContext.Provider>
  );
}
