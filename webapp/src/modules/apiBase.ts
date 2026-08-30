import {
  debugRequestLogger,
  debugResponseLogger,
  errorResponseLogger,
} from "./apilogger";
import axios, {
  AxiosError,
  AxiosRequestConfig,
  AxiosResponse,
  CanceledError,
  InternalAxiosRequestConfig,
} from "axios";
import humps from "humps";

declare module "axios" {
  interface AxiosRequestConfig {
    // Custom flag consumed by the response interceptor below; set false to
    // skip camelCase-ing a response body.
    camelize?: boolean;
  }
}

interface CreateOptions extends AxiosRequestConfig {
  debug?: boolean;
  chaos?: number;
}

function create(apiHost: string, config?: CreateOptions) {
  const { debug, chaos, ...rest } = config || {};
  const instance = axios.create({
    baseURL: apiHost,
    timeout: 20000,
    withCredentials: true,
    transformRequest: [
      (data) => humps.decamelizeKeys(data),
      ...([] as any[]).concat(axios.defaults.transformRequest),
    ],
    transformResponse: ([] as any[]).concat(axios.defaults.transformResponse),
    ...rest,
  });
  instance.interceptors.response.use((response) => {
    if (typeof response.data === "object" && response.config.camelize !== false) {
      response.data = humps.camelizeKeys(response.data);
    }
    return response;
  });
  if (debug) {
    console.log(
      "apiBase: Debug mode enabled, setting up Axios logging for calls to",
      apiHost
    );
    instance.interceptors.request.use(...debugRequestLogger);
    instance.interceptors.response.use(...debugResponseLogger);
  } else {
    instance.interceptors.response.use(...errorResponseLogger);
  }
  if (chaos) {
    console.log(
      `apiBase: Chaos mode enabled (${chaos}), adding random delays to api calls`
    );
    instance.interceptors.request.use(requestChaos(chaos));
  }
  return instance;
}

function requestChaos(chaos: number) {
  const chaosMult = chaos === 0 ? 1 : chaos;
  return (reqConfig: InternalAxiosRequestConfig) => {
    // Add some delay into api calls to simulate real-world behavior.
    let debugDelay = 250 + Math.random() * 1000;
    // Add some p90 and p95 latencies
    const percentile = Math.random();
    if (percentile < 0.05) {
      debugDelay += 3000 + Math.random() * 4000;
    } else if (percentile < 0.1) {
      debugDelay += 1000 + Math.random() * 2000;
    }
    debugDelay *= chaosMult;
    return Promise.resolve(reqConfig).delay(debugDelay);
  };
}

function mergeParams(params: Record<string, any> | undefined, o: Record<string, any>) {
  const cased = humps.decamelizeKeys(params || {});
  return { params: cased, ...o };
}

function isAxiosTimeout(r: unknown) {
  if (r instanceof CanceledError) {
    return true;
  }
  if (r instanceof AxiosError && r.code === "ECONNABORTED") {
    return true;
  }
  return false;
}

function pickData<T>(o: AxiosResponse<T>) {
  return o.data;
}

export default {
  create,
  isAxiosTimeout,
  mergeParams,
  pickData,
};
