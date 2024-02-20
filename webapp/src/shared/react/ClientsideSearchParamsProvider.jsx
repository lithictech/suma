import badContext from "./badContext";
import React from "react";
import { useLocation } from "react-router-dom";

/**
 * @typedef ClientsideSearchParams
 * @property {URLSearchParams} searchParams
 * @property {function} replaceSearchParams Replace the entire URL with the new params.
 *   Can be an object or a URLSearchParams instance.
 * @property {function} setSearchParam Replace a specific search param in the URL.
 */

export const ClientsideSearchParamsContext = React.createContext({
  searchParams: new URLSearchParams(),
  replaceSearchParams: badContext("ClientsideSearchParams"),
  setSearchParam: badContext("ClientsideSearchParams"),
});

export default function ClientsideSearchParamsProvider({ children }) {
  const location = useLocation();
  const [searchParamsState, setSearchParamsState] = React.useState(
    new URLSearchParams(window.location.search)
  );

  React.useEffect(() => {
    setSearchParamsState(new URLSearchParams(location.search));
  }, [location]);

  const replaceSearchParams = React.useCallback((arg) => {
    if (!(arg instanceof URLSearchParams)) {
      arg = new URLSearchParams(arg);
    }
    const url = new URL(window.location.href);
    url.search = arg.toString();
    window.history.pushState({}, null, url);
    setSearchParamsState(arg);
  }, []);

  const setSearchParam = React.useCallback(
    (k, val) => {
      const newparams = new URLSearchParams(searchParamsState);
      if (val === null || val === undefined) {
        newparams.delete(k);
      } else {
        newparams.set(k, val);
      }
      replaceSearchParams(newparams);
    },
    [replaceSearchParams, searchParamsState]
  );

  const value = React.useMemo(
    () => ({
      searchParams: searchParamsState,
      replaceSearchParams,
      setSearchParam,
    }),
    [replaceSearchParams, searchParamsState, setSearchParam]
  );
  return (
    <ClientsideSearchParamsContext.Provider value={value}>
      {children}
    </ClientsideSearchParamsContext.Provider>
  );
}
