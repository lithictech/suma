import { Logger } from "../shared/logger";
import get from "lodash/get";
import isString from "lodash/isString";
import React from "react";

const logger = new Logger("form-error");

export function useError(initialState) {
  const [error, setErrorInner] = React.useState(initialState || null);

  /**
   * @param {any=} e
   * @return {null}
   */
  const setError = React.useCallback(function setError(e) {
    setErrorInner(e);
    return null;
  }, []);
  return [error, setError];
}

/**
 * @return {string|null}
 */
export function extractErrorCode(error) {
  if (!error || isString(error)) {
    return error;
  }
  if (get(error, "message") === "Network Error") {
    return "network_error";
  }
  const status = get(error, "response.data.error.status") || 500;
  let msg;
  if (status >= 500) {
    msg = defaultCode;
  } else {
    msg = get(error, "response.data.error.code") || defaultCode;
  }
  if (msg === defaultCode) {
    // We couldn't parse anything meaningful, so log it out
    logger.error(error);
  }
  return msg;
}

const defaultCode = "unhandled_error";
