import { Logger } from "./logger";
import type { AxiosError, AxiosResponse, InternalAxiosRequestConfig } from "axios";
import get from "lodash/get";
import identity from "lodash/identity";
import omit from "lodash/omit";

const reqLogger = new Logger("api.requests");
const respLogger = new Logger("api.responses");

function reqSuccessDebug(config: InternalAxiosRequestConfig) {
  // https://github.com/axios/axios#request-config
  reqLogger.tags({ method: method(config), url: config.url }).debug("api_request");
  return config;
}

function reqError(error: any) {
  reqLogger.exception("request_error", error);
  return Promise.reject(error);
}

function respSuccessDebug(response: AxiosResponse) {
  // https://github.com/axios/axios#response-schema
  let body = JSON.stringify(response.data);
  if (body.length > 103) {
    body = body.slice(0, 100) + "...";
  }
  respLogger
    .tags({
      method: method(response.config),
      url: response.config.url,
      status: response.status,
    })
    .context({ body })
    .info("api_response");
  return response;
}

function respErrorDebug(error: AxiosError) {
  if (error.response) {
    respSuccessDebug(error.response);
  } else {
    respLogger
      .tags({
        method: method(error.config as InternalAxiosRequestConfig),
        url: error.config?.url,
        non_http_response_error: true,
      })
      .error(error.message);
  }
  return Promise.reject(error);
}

function method(c: InternalAxiosRequestConfig) {
  return c.method?.toUpperCase();
}

export const debugRequestLogger: [typeof reqSuccessDebug, typeof reqError] = [
  reqSuccessDebug,
  reqError,
];
export const debugResponseLogger: [typeof respSuccessDebug, typeof respErrorDebug] = [
  respSuccessDebug,
  respErrorDebug,
];

function respErrorFull(error: AxiosError) {
  if (get(error, "response.status") === 401) {
    return Promise.reject(error);
  }
  let tags: Record<string, any> = {
    method: method(error.config as InternalAxiosRequestConfig),
    url: error.config?.url,
  };
  if (!error.response) {
    tags.non_http_response_error = true;
    respLogger.tags(tags).error(error.message);
    return Promise.reject(error);
  }
  const apiErr = get(error, "response.data.error");
  if (apiErr) {
    tags = omit({ ...tags, ...(apiErr as object) }, "backtrace");
  }
  tags.status = error.response.status;
  respLogger
    .tags(tags)
    .context({ message: error.message })
    .error(`${tags.method} ${tags.url} ${tags.status}`);
  return Promise.reject(error);
}

export const errorResponseLogger: [typeof identity, typeof respErrorFull] = [
  identity,
  respErrorFull,
];
