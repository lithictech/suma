import { AxiosResponse } from "axios";
import get from "lodash/get";
import React from "react";
import { Location } from "react-router-dom";

/**
 * Perform an async fetch, which must hit the API.
 *
 * Note that the fetch does not accept an axios request configuration,
 * since it is not part of the cache key.
 *
 * If callers require passing the configuration,
 * they can wrap the fetch in a useCallback.
 */
type AsyncFetch<T> = (data?: Record<string, any>) => Promise<AxiosResponse<T>>;

/**
 * Similar to AsyncDataFetch,
 * but returns the underlying data, not the response.
 * The data may be returned from the cache.
 */
type AsyncDataFetch<T> = (data?: Record<string, any>) => Promise<T>;

interface UseAsyncFetchOptions<T = any> {
  default?: T;
  /** If true, do not fetch right away. You will need to call asyncFetch manually. */
  doNotFetchOnInit?: boolean;
  /**
   * If given, pull this field from location.state as the initial/default value.
   * Allows passing of data in the history state, while fetching from the URL if it is not present.
   * The state is cleared as soon as it is fetched, since it can get stale quickly
   * as it does not behave like React state (ie it persists between refreshses).
   */
  pullFromState?: string;
  /** Must be provided for pullFromState to be used. */
  location?: Location;
  /**
   * If true, cache the API response using the options as a key.
   * When caching, the arguments passed to makeRequest MUST be serializable using JSON.stringify.
   */
  cache?: boolean;
}

interface UseAsyncFetchResult<T = any> {
  state: T;
  response: AxiosResponse<T>;
  replaceState: React.Dispatch<React.SetStateAction<T>>;
  asyncFetch: AsyncFetch<T>;
  error: any;
  loading: boolean;
}

// When `default` is provided, `state` is never undefined.
function useAsyncFetch<T>(
  makeRequest: AsyncFetch<T>,
  options: UseAsyncFetchOptions<T> & { default: T }
): UseAsyncFetchResult<T>;

function useAsyncFetch<T = any>(
  makeRequest: AsyncFetch<T>,
  options?: UseAsyncFetchOptions<T>
): UseAsyncFetchResult<T | undefined>;

function useAsyncFetch<T = any>(
  makeRequest: AsyncFetch<T>,
  options?: UseAsyncFetchOptions<T>
) {
  const { location, pullFromState, cache } = options || {};
  let { default: defaultVal, doNotFetchOnInit } = options || {};
  if (pullFromState && get(location, ["state", pullFromState])) {
    defaultVal = location?.state?.[pullFromState];
    doNotFetchOnInit = true;
    window.history.replaceState({}, document.title);
  }
  const [state, setState] = React.useState<T | undefined>(defaultVal);
  const [response, setResponse] = React.useState<AxiosResponse<T> | undefined>();
  const [error, setError] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(!doNotFetchOnInit);
  const cacheRef = React.useRef<Record<string, any>>({});

  const asyncFetch: AsyncDataFetch<T> = React.useCallback(
    (data) => {
      setLoading(true);
      setError(false);
      let cacheKey: string;
      if (cache) {
        // If we're caching, and the entry is in the cache,
        // then return it from the cache. Use a 200ms delay to mimic a very fast
        // network call, since when callers use this they normally expect some delay.
        // We can add options to control this in the future.
        cacheKey = "" + makeRequest + JSON.stringify(data);
        const cached = cacheRef.current[cacheKey];
        if (cached) {
          return Promise.delay(200, Promise.resolve()).then(() => {
            const st = cached as T;
            setState(st);
            setLoading(false);
            return st;
          });
        }
      }
      return makeRequest(data)
        .then((r) => {
          setResponse(r);
          setState(r.data);
          if (cache) {
            cacheRef.current[cacheKey] = r.data;
          }
          return r.data;
        })
        .tapCatch((e) => setError(e))
        .tap(() => setLoading(false))
        .tapCatch(() => setLoading(false));
    },
    [cache, makeRequest]
  );

  React.useEffect(() => {
    if (!doNotFetchOnInit) {
      asyncFetch().then();
    }
  }, [asyncFetch, doNotFetchOnInit]);
  return {
    state,
    response,
    replaceState: setState,
    asyncFetch,
    error,
    loading,
  };
}

export default useAsyncFetch;
