import qs from "../queryString";
import _ from "lodash";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";

/**
 * Like React.setState, but with a query param.
 * @param {string} key Name of the query param.
 * @param {any} defaultValue Default for the param if not in the query string. Can be any type (See parse and serialize).
 * @param {function(string): any} parse If given, parse the string from the query param into a typed value.
 * @param {function(any): string} serialize If given, serialize a typed value into a string for use in the query param.
 */
export default function useQueryParam(key, defaultValue, { parse, serialize } = {}) {
  const navigate = useNavigate();
  const location = useLocation();

  const parsed = qs.parse(location.search);

  let queryParamState = defaultValue;
  if (_.has(parsed, key)) {
    queryParamState = parsed[key];
  }

  if (parse) {
    queryParamState = parse(queryParamState);
  }

  const setQueryParamState = React.useCallback(
    (value) => {
      let toWrite = value;
      if (toWrite === null) {
        toWrite = undefined;
      }
      if (serialize) {
        toWrite = serialize(toWrite);
      }
      const params = {
        ...qs.parse(location.search),
        [key]: toWrite,
      };
      navigate(`${location.pathname}?${qs.stringify(params)}`);
    },
    [navigate, key, location, serialize]
  );

  return [queryParamState, setQueryParamState];
}
