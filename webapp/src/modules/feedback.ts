import { t } from "../localization";
import { Logger } from "./logger";
import { AxiosError } from "axios";
import get from "lodash/get";
import React from "react";

const logger = new Logger("form-error");

type ErrorCode = string;

export class AppError {
  code: string;
  opts: Record<string, any>;
  explicit?: string;

  constructor(code: string, opts: Record<string, any>, explicit?: string) {
    this.code = code;
    this.opts = opts;
    this.explicit = explicit;
  }

  render(): React.ReactNode {
    if (this.explicit) {
      return this.explicit;
    }
    const msg = t(`errors.${this.code}`, this.opts);
    return msg;
  }
}

export function appError(code: string, opts?: Record<string, any>) {
  return new AppError(code, opts || {});
}

/**
 * Version of extractAppError that can be used when 'any' type is needed.
 * @param error
 */
export function extractAppErrorAny(error: any): AppError {
  return extractAppErrorImpl(error);
}

/**
 * Extract an app error from an error.
 */
export function extractAppError(error: AxiosError | Error | ErrorCode): AppError {
  return extractAppErrorImpl(error);
}

function extractAppErrorImpl(error: AxiosError | Error | ErrorCode | any): AppError {
  if (get(error, "message") === "Network Error") {
    return new AppError("network_error", {});
  }
  const status = get(error, "response.data.error.status") || 500;
  const opts: Record<string, any> = {};
  let msg: string;
  if (status >= 500) {
    msg = defaultCode;
  } else {
    msg = get(error, "response.data.error.code") || defaultCode;
  }
  if (msg === defaultCode) {
    // We couldn't parse anything meaningful, so log it out
    logger.error("" + error);
  } else if (msg === "too_many_requests") {
    opts.seconds = Number(get(error, "response.data.error.retryAfter", 60));
  }
  return new AppError(msg, opts);
}

const defaultCode = "unhandled_error";

export class Success {
  value: React.ReactNode;
  constructor(value: React.ReactNode) {
    this.value = value;
  }
}

export function success(value: React.ReactNode) {
  return new Success(value);
}

export type FeedbackValue = Success | AppError;
