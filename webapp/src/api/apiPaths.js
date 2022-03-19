import config from "./config";

const { sumaApiHost } = config;
const apiV1 = "v1";

export const API_PATH_START = `${sumaApiHost}/api/${apiV1}/start`;
export const API_PATH_VERIFY_PHONE = `${sumaApiHost}/api/${apiV1}/verify`;