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
 * @param {boolean=} options.cache If true, cache the API response using the options as a key.
 *   When caching, the arguments passed to makeRequest MUST be serializable using JSON.stringify.
 * @returns {{state, asyncFetch, error, loading}}
 */
const useAsyncFetch = (makeRequest, options) => {
  let {
    default: defaultVal,
    doNotFetchOnInit,
    location,
    pickData,
    pullFromState,
    cache,
  } = options || {};
  if (pullFromState && get(location, ["state", pullFromState])) {
    defaultVal = location.state[pullFromState];
    doNotFetchOnInit = true;
    window.history.replaceState({}, document.title);
  }
  const [state, setState] = React.useState(defaultVal);
  const [error, setError] = React.useState(null);
  const [loading, setLoading] = React.useState(!doNotFetchOnInit);
  const cacheRef = React.useRef({});

  const asyncFetch = React.useCallback(
    (...args) => {
      setLoading(true);
      setError(false);
      let cacheKey;
      if (cache) {
        // If we're caching, and the entry is in the cache,
        // then return it from the cache. Use a 200ms delay to mimic a very fast
        // network call, since when callers use this they normally expect some delay.
        // We can add options to control this in the future.
        cacheKey = "" + makeRequest + JSON.stringify(args);
        if (cacheRef.current[cacheKey]) {
          return Promise.delay(200).then(() => {
            const st = cacheRef.current[cacheKey];
            setState(st);
            setLoading(false);
            return st;
          });
        }
      }
      return makeRequest(...args)
        .then((x) => {
          const st = pickData ? x.data : x;
          setState(st);
          if (cache) {
            cacheRef.current[cacheKey] = st;
          }
          return st;
        })
        .tapCatch((e) => setError(e))
        .tap(() => setLoading(false))
        .tapCatch(() => setLoading(false));
    },
    [cache, makeRequest, pickData]
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
