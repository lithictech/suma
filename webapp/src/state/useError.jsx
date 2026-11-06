import { t } from "../localization";
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
 * Returns the error code string. For backend validation errors that include
 * per-field messages, returns a localized element that lists them
 * (3.3.1/3.3.3: the user learns which field failed, not just that one did).
 * Callers comparing against a specific code string are unaffected.
 * @return {string|JSX.Element|null}
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
  if (msg === "validation_error") {
    const details = get(error, "response.data.error.errors");
    if (Array.isArray(details) && details.length > 0) {
      return renderValidationErrorMessage(details);
    }
  }
  return msg;
}

/**
 * The localized validation message, followed by the backend's field messages.
 * Rendered with spans (not ul/li) since FormError renders inside a <p>.
 * The backend messages are not localized, so mark them as English (3.1.2).
 */
function renderValidationErrorMessage(details) {
  return (
    <>
      {t("errors.validation_error")}
      <span role="list" className="d-block mt-1" lang="en">
        {details.map((d, i) => (
          <span key={i} role="listitem" className="d-block">
            {d}
          </span>
        ))}
      </span>
    </>
  );
}

const defaultCode = "unhandled_error";

/**
 * Use extractErrorCode to get the code for error,
 * then render it in a localized element.
 * Uses special casing to localize the error message
 * using information returned from 'error'.
 * @param error
 * @returns {JSX.Element}
 */
export function extractLocalizedError(error) {
  const code = extractErrorCode(error);
  if (React.isValidElement(code)) {
    return code;
  }
  const opts = {};
  if (code === "too_many_requests") {
    opts.seconds = Number(get(error, "response.data.error.retryAfter", 60));
  }
  const msg = t(`errors.${code}`, opts);
  return <>{msg}</>;
}
