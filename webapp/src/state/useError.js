import { Logger } from "../shared/logger";
import _ from "lodash";
import React from "react";

const logger = new Logger("form-error");

export function useError(initialState) {
  const [error, setErrorInner] = React.useState(initialState || null);

  /**
   * @param {any=} e
   * @return {null}
   */
  function setError(e) {
    setErrorInner(e);
    return null;
  }
  return [error, setError];
}

/**
 * @return {string|null}
 */
export function extractErrorCode(error) {
  if (!error || _.isString(error)) {
    return error;
  }
  const status = _.get(error, "response.data.error.status") || 500;
  let msg;
  if (status >= 500) {
    msg = defaultCode;
  } else {
    msg = _.get(error, "response.data.error.code") || defaultCode;
  }
  if (msg === defaultCode) {
    // We couldn't parse anything meaningful, so log it out
    logger.error(error);
  }
  return msg;
}

const defaultCode = "unhandled_error";
