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
 * @param {string=} options.key Key to use. Default to apiGet as string.
 * @returns {*} The default value before the API call is resolved
 *   (before it's made, while it's pending, if it's rejected),
 *   or the picked value (like response.data) once the API call is resolved.
 */
export function useGlobalApiState(apiGet, defaultValue, options) {
  options = merge({}, defaultOptions, options);
  const { hasKey, getKey, setKey } = React.useContext(GlobalApiStateContext);
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const key = "" + (options.key || apiGet);
  React.useEffect(() => {
    if (hasKey(key)) {
      return;
    }
    apiGet()
      .then((r) => setKey(key, r))
      .catch(enqueueErrorSnackbar);
    setKey(key, loading);
  }, [enqueueErrorSnackbar, apiGet, key, hasKey, setKey]);
  if (hasKey(key)) {
    const r = getKey(key);
    return r === loading ? defaultValue : options.pick(r);
  }
  return defaultValue;
}

export function GlobalApiStateProvider({ children }) {
  // Under the hood, we need to save the state into a ref,
  // because we don't want to make multiple API calls for the same request.
  // But it is very easy for children to be working with different views of the state
  // (ie, when useGlobalApiState is used in multiple places in the tree)
  // and trigger multiple api calls (because both components are adding keys when they render).
  //
  // Whenever we write to the ref, we also modify the state,
  // which causes children to re-render, calling getKey and seeing the new state stored in the ref.
  //
  // If we just had the ref (no state), modifying the ref would not cause any re-renders
  // and children would not see the new data.
  const storage = React.useRef({});
  const [dummyState, setDummyState] = React.useState({});
  const hasKey = React.useCallback((k) => has(storage.current, k), [storage]);
  const getKey = React.useCallback((k) => storage.current[k], [storage]);
  const setKey = React.useCallback(
    (k, v) => {
      storage.current = { ...storage.current, [k]: v };
      setDummyState({ ...dummyState, [k]: v });
    },
    [dummyState]
  );
  return (
    <GlobalApiStateContext.Provider value={{ hasKey, getKey, setKey }}>
      {children}
    </GlobalApiStateContext.Provider>
  );
}

function pickData(r) {
  return r.data;
}
const defaultOptions = { pick: pickData };
