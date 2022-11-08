import React from "react";

/**
 * @param makeRequest
 * @param {object=} options
 * @param {*=} options.default
 * @param {boolean=} options.doNotFetchOnInit
 * @param {boolean=} options.pickData
 * @returns {{state, asyncFetch, error, loading}}
 */
const useAsyncFetch = (makeRequest, options) => {
  options = options || {};
  const [state, setState] = React.useState(options.default);
  const [error, setError] = React.useState(null);
  const [loading, setLoading] = React.useState(!options.doNotFetchOnInit);

  const asyncFetch = React.useCallback(
    (...args) => {
      setLoading(true);
      setError(false);
      return makeRequest(...args)
        .then((x) => {
          const st = options.pickData ? x.data : x;
          setState(st);
          return st;
        })
        .tapCatch((e) => setError(e))
        .tap(() => setLoading(false))
        .tapCatch(() => setLoading(false));
    },
    [makeRequest, options.pickData]
  );

  React.useEffect(() => {
    if (!options.doNotFetchOnInit) {
      asyncFetch();
    }
  }, [asyncFetch, options.doNotFetchOnInit]);
  return {
    state,
    asyncFetch,
    error,
    loading,
  };
};

export default useAsyncFetch;
