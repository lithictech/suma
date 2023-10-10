import get from "lodash/get";
import React from "react";

/**
 * @param makeRequest
 * @param {object=} options
 * @param {*=} options.default
 * @param {boolean=} options.doNotFetchOnInit If true, do not fetch right away.
 *   You will need to call asyncFetch manually.
 * @param {boolean=} options.pickData The 'state' will pick the 'data' field of the response,
 *   rather than being an axios Response.
 * @param {string=} options.pullFromState If given, pull this field from location.state as the initial/default value.
 *   Allows passing of data in the history state, while fetching from the URL if it is not present.
 *   The state is cleared as soon as it is fetched, since it can get stale quickly
 *   as it does not behave like React state (ie it persists between refreshses).
 * @param {Location=} options.location Must be provided for pullFromState to be used.
 * @returns {{state, asyncFetch, error, loading}}
 */
const useAsyncFetch = (makeRequest, options) => {
  let {
    default: defaultVal,
    doNotFetchOnInit,
    location,
    pickData,
    pullFromState,
  } = options || {};
  if (pullFromState && get(location, ["state", pullFromState])) {
    defaultVal = location.state[pullFromState];
    doNotFetchOnInit = true;
    window.history.replaceState({}, document.title);
  }
  const [state, setState] = React.useState(defaultVal);
  const [error, setError] = React.useState(null);
  const [loading, setLoading] = React.useState(!doNotFetchOnInit);

  const asyncFetch = React.useCallback(
    (...args) => {
      setLoading(true);
      setError(false);
      return makeRequest(...args)
        .then((x) => {
          const st = pickData ? x.data : x;
          setState(st);
          return st;
        })
        .tapCatch((e) => setError(e))
        .tap(() => setLoading(false))
        .tapCatch(() => setLoading(false));
    },
    [makeRequest, pickData]
  );

  React.useEffect(() => {
    if (!doNotFetchOnInit) {
      asyncFetch();
    }
  }, [asyncFetch, doNotFetchOnInit]);
  return {
    state,
    replaceState: setState,
    asyncFetch,
    error,
    loading,
  };
};

export default useAsyncFetch;
