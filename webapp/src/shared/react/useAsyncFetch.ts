import get from "lodash/get";
import React from "react";

interface UseAsyncFetchOptions<T = any> {
  default?: T;
  /** If true, do not fetch right away. You will need to call asyncFetch manually. */
  doNotFetchOnInit?: boolean;
  /** The 'state' will pick the 'data' field of the response, rather than being an axios Response. */
  pickData?: boolean;
  /**
   * If given, pull this field from location.state as the initial/default value.
   * Allows passing of data in the history state, while fetching from the URL if it is not present.
   * The state is cleared as soon as it is fetched, since it can get stale quickly
   * as it does not behave like React state (ie it persists between refreshses).
   */
  pullFromState?: string;
  /** Must be provided for pullFromState to be used. */
  location?: { state?: Record<string, any> };
  /**
   * If true, cache the API response using the options as a key.
   * When caching, the arguments passed to makeRequest MUST be serializable using JSON.stringify.
   */
  cache?: boolean;
}

const useAsyncFetch = <T = any>(
  makeRequest: (...args: any[]) => Promise<any>,
  options?: UseAsyncFetchOptions<T>
) => {
  const { location, pickData, pullFromState, cache } = options || {};
  let { default: defaultVal, doNotFetchOnInit } = options || {};
  if (pullFromState && get(location, ["state", pullFromState])) {
    defaultVal = location.state[pullFromState];
    doNotFetchOnInit = true;
    window.history.replaceState({}, document.title);
  }
  const [state, setState] = React.useState(defaultVal);
  const [error, setError] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(!doNotFetchOnInit);
  const cacheRef = React.useRef<Record<string, any>>({});

  const asyncFetch = React.useCallback(
    (...args: any[]) => {
      setLoading(true);
      setError(false);
      let cacheKey: string;
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
