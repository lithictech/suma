import React from "react";

export const GlobalViewStateContext = React.createContext();

/**
 * @typedef GlobalViewState
 * @property {Element=} topNav The element with the logo and hamburger.
 * @property {function(Element=): void} setTopNav
 * @property {Element=} appNav The element with the tab sections (home, mobility, etc).
 * @property {function(Element=): void} setTopNav
 */

/**
 * Global view state manages global state about the view,
 * like the DOM elements for navigation.
 * @returns {GlobalViewState}
 */
export const useGlobalViewState = () => React.useContext(GlobalViewStateContext);

export function GlobalViewStateProvider({ children }) {
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
