import config from "./config";
import apiBase from "./shared/apiBase";

const instance = apiBase.create(config.apiHost, {
  debug: config.debug,
  chaos: config.chaos,
});

const get = (path, params, opts) => {
  return instance.get(path, apiBase.mergeParams(params, opts));
};
const post = (path, params, opts) => {
  return instance.post(path, params, opts);
};
const patch = (path, params, opts) => {
  return instance.patch(path, params, opts);
};

const put = (path, params, opts) => {
  return instance.put(path, params, opts);
};

const del = (path, params, opts) => {
  return instance.delete(path, apiBase.mergeParams(params, opts));
};

export default {
  ...apiBase,
  get,
  post,
  patch,
  put,
  del,
  getMe: (data) => get(`/api/v1/me`, data),
  updateMe: (data) => post(`/api/v1/me/update`, data),
  getSupportedGeographies: (data) => get(`/api/v1/meta/supported_geographies`, data),
  getSupportedCurrencies: (data) => get(`/api/v1/meta/supported_currencies`, data),
  dashboard: (data) => get("/api/v1/me/dashboard", data),
  authStart: (data) => post(`/api/v1/auth/start`, data),
  authVerify: (data) => post(`/api/v1/auth/verify`, data),
  authSignout: (data) => del(`/api/v1/auth`, data),
  getMobilityMap: (data) => get("/api/v1/mobility/map", data),
  getMobilityVehicle: (data) => get("/api/v1/mobility/vehicle", data),
  beginMobilityTrip: (data) => post("/api/v1/mobility/begin_trip", data),
  endMobilityTrip: (data) => post("/api/v1/mobility/end_trip", data),
  getUserAgent: () => get("/api/useragent"),

  createBankAccount: (data) =>
    post(`/api/v1/payment_instruments/bank_accounts/create`, data),
  deleteBankAccount: (data) =>
    del(`/api/v1/payment_instruments/bank_accounts/${data.id}`, data),

  createFundingPayment: (data) => post(`/api/v1/payments/create_funding`, data),
};
