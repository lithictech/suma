import React from "react";

export const GlobalViewStateContext = React.createContext({});

export default function GlobalViewStateProvider({ children }) {
  const [topNav, setTopNav] = React.useState(null);
  const [appNav, setAppNav] = React.useState(null);
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
