import { t } from "../localization";
import { Logger } from "../shared/logger";
import get from "lodash/get";
import isString from "lodash/isString";
import React from "react";

const logger = new Logger("form-error");

export function useError(initialState?: any): [any, (e?: any) => null] {
  const [error, setErrorInner] = React.useState(initialState || null);

  const setError = React.useCallback(function setError(e?: any) {
    setErrorInner(e);
    return null;
  }, []);
  return [error, setError];
}

export function extractErrorCode(error: any): any {
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

/**
 * Use extractErrorCode to get the code for error,
 * then render it in a localized element.
 * Uses special casing to localize the error message
 * using information returned from 'error'.
 */
export function extractLocalizedError(error: any) {
  const code = extractErrorCode(error);
  const opts: Record<string, any> = {};
  if (code === "too_many_requests") {
    opts.seconds = Number(get(error, "response.data.error.retryAfter", 60));
  }
  const msg = t(`errors.${code}`, opts);
  return <>{msg}</>;
}
