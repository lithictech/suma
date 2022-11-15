import _ from "lodash";
import React from "react";

/**
 * @param makeRequest
 * @param {object=} options
 * @param {*=} options.default
 * @param {boolean=} options.doNotFetchOnInit
 * @param {boolean=} options.pickData
 * @param {string=} options.pullFromState
 * @param {Location=} options.location
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
  if (pullFromState && _.get(location, ["state", pullFromState])) {
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
    asyncFetch,
    error,
    loading,
  };
};

export default useAsyncFetch;
