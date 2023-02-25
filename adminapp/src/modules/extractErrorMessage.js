import { Logger } from "../shared/logger";
import get from "lodash/get";
import isString from "lodash/isString";

export default function extractErrorMessage(error, defaultMsg) {
  if (!error || isString(error)) {
    return error;
  }
  const status = get(error, "response.data.error.status") || 500;
  let msg;
  if (status >= 500) {
    msg = defaultMessage;
  } else {
    msg = get(error, "response.data.error.message") || defaultMsg || defaultMessage;
  }
  if (msg === defaultMsg) {
    // We couldn't parse anything meaningful, so log it out
    logger.error(error);
  }
  return msg;
}

const logger = new Logger("errmsg");

const defaultMessage = "Something went wrong. Please try again.";
