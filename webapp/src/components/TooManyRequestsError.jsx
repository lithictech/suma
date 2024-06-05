import { t } from "../localization";
import useMountEffect from "../shared/react/useMountEffect";
import get from "lodash/get";
import React from "react";

/**
 * Returns a localized 'too_many_requests' error string including
 * a countdown timer that lasts for the duration of the retryAfter error value.
 * @param error The error to fetch the 'retryAfter' duration value from
 * @returns {string|null}
 * @constructor
 */
export default function TooManyRequestsError({ error }) {
  const duration = Number(get(error, "response.data.error.retryAfter", 0));
  const [countdown, setCountdown] = React.useState(duration);
  let timerId = 0;
  useMountEffect(() => {
    timerId = setInterval(() => {
      setCountdown((prev) => prev - 1);
    }, 1000);
    return () => clearInterval(timerId);
  });
  if (countdown <= 0) {
    clearInterval(timerId);
    return null;
  }
  const minutes = Math.floor(countdown / 60);
  const seconds = countdown % 60;
  const minutesCtx = t("auth:minutes", { count: minutes });
  const secondsCtx = t("auth:seconds", { count: seconds });
  const retryAfter =
    minutes === 0
      ? secondsCtx
      : t("auth:minutes_and_seconds", { minutes: minutesCtx, seconds: secondsCtx });
  return t("errors:too_many_requests", { retryAfter: retryAfter });
}
