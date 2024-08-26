import useErrorSnackbar from "./useErrorSnackbar";
import has from "lodash/has";
import merge from "lodash/merge";
import React from "react";

export const GlobalApiStateContext = React.createContext();

const loading = Symbol("globalApiStateLoading");

/**
 * Helper for working with meta or rarely-changing API calls,
 * so they can be cached on the client in a context.
 * @param {function} apiGet
 * @param {*} defaultValue
 * @param {object=} options
 * @param {function=} options.pick Called with the response, to pick the data for the state.
 *   Defaults to `(r) => r.data`.
 * @returns {*}
 */
export function useGlobalApiState(apiGet, defaultValue, options) {
  options = merge({ pick: (r) => r.data }, options);
  const { state, setState } = React.useContext(GlobalApiStateContext);
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const key = "" + apiGet;
  React.useEffect(() => {
    if (has(state, key)) {
      return;
    }
    apiGet()
      .then((r) => setState({ ...state, [key]: r }))
      .catch(enqueueErrorSnackbar);
    setState({ ...state, [key]: loading });
  }, [enqueueErrorSnackbar, state, apiGet, setState, key, options]);
  if (has(state, key)) {
    const r = state[key];
    return r === loading ? defaultValue : options.pick(r);
  }
  return defaultValue;
}

export function GlobalApiStateProvider({ children }) {
  const [state, setState] = React.useState({});
  return (
    <GlobalApiStateContext.Provider value={{ state, setState }}>
      {children}
    </GlobalApiStateContext.Provider>
  );
}
