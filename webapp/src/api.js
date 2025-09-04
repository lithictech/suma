import config from "./config";
import { getCurrentLanguage } from "./localization/currentLanguage";
import apiBase from "./shared/apiBase";
import axiosRetry, { isIdempotentRequestError, isNetworkError } from "axios-retry";

const instance = apiBase.create(config.apiHost, {
  debug: config.debug,
  chaos: config.chaos || false,
});
axiosRetry(instance, {
  shouldResetTimeout: true,
  retryCondition: (error) => {
    return (
      isNetworkError(error) ||
      isIdempotentRequestError(error) ||
      (SAFE_HTTP_METHODS.includes(error.config.method) && error.code === "ECONNABORTED")
    );
  },
});

const SAFE_HTTP_METHODS = ["get", "head", "options"];

instance.interceptors.request.use(
  (config) => {
    config.headers["Accept-Language"] = getCurrentLanguage();
    return config;
  },
  (error) => Promise.reject(error)
);

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
  axios: instance,
  get,
  post,
  patch,
  put,
  del,
  getMe: (data, ...args) => get(`/api/v1/me`, data, ...args),
  updateMe: (data, ...args) => post(`/api/v1/me/update`, data, ...args),
  changeLanguage: (data, ...args) => post(`/api/v1/me/language`, data, ...args),
  getSupportedGeographies: (data, ...args) =>
    get(`/api/v1/meta/supported_geographies`, data, ...args),
  getSupportedLocales: (data, ...args) =>
    get(`/api/v1/meta/supported_locales`, data, ...args),
  getSupportedCurrencies: (data, ...args) =>
    get(`/api/v1/meta/supported_currencies`, data, ...args),
  getSupportedPaymentMethods: (data, ...args) =>
    get(`/api/v1/meta/supported_payment_methods`, data, ...args),
  geolocateIp: (data, ...args) => get(`/api/v1/meta/geolocate_ip`, data, ...args),
  getSupportedOrganizations: (data, ...args) =>
    get(`/api/v1/meta/supported_organizations`, data, ...args),
  getLocaleFile: ({ namespace, locale, ...data }, ...args) =>
    get(`/api/v1/meta/static_strings/${locale}/${namespace}`, data, ...args),
  dashboard: (data, ...args) => get("/api/v1/me/dashboard", data, ...args),
  getLedgersOverview: (data, ...args) => get("/api/v1/ledgers/overview", data, ...args),
  getLedgerLines: ({ id, ...data }, ...args) =>
    get(`/api/v1/ledgers/${id}/lines`, data, ...args),
  authStart: (data, ...args) => post(`/api/v1/auth/start`, data, ...args),
  authVerify: (data, ...args) => post(`/api/v1/auth/verify`, data, ...args),
  authContactList: (data, ...args) => post(`/api/v1/auth/contact_list`, data, ...args),
  authSignout: (data, ...args) => del(`/api/v1/auth`, data, ...args),
  getMobilityMap: (data, ...args) => get("/api/v1/mobility/map", data, ...args),
  getMobilityMapFeatures: (data, ...args) =>
    get("/api/v1/mobility/map_features", data, ...args),
  getMobilityVehicle: (data, ...args) => get("/api/v1/mobility/vehicle", data, ...args),
  beginMobilityTrip: (data, ...args) =>
    post("/api/v1/mobility/begin_trip", data, ...args),
  endMobilityTrip: (data, ...args) => post("/api/v1/mobility/end_trip", data, ...args),
  getMobilityTrips: (data, ...args) => get("/api/v1/mobility/trips", data, ...args),
  getUserAgent: () => get("/api/useragent"),
  getCommerceOfferings: () => get("/api/v1/commerce/offerings"),
  getCommerceOfferingDetails: ({ id, ...data }, ...args) =>
    get(`/api/v1/commerce/offerings/${id}`, data, ...args),
  putCartItem: ({ offeringId, ...data }, ...args) =>
    put(`/api/v1/commerce/offerings/${offeringId}/cart/item`, data, ...args),
  startCheckout: ({ offeringId, ...data }, ...args) =>
    post(`/api/v1/commerce/offerings/${offeringId}/checkout`, data, ...args),
  getCheckout: ({ id, ...data }, ...args) =>
    get(`/api/v1/commerce/checkouts/${id}`, data, ...args),
  updateCheckoutFulfillment: ({ checkoutId, ...data }, ...args) =>
    post(`/api/v1/commerce/checkouts/${checkoutId}/modify_fulfillment`, data, ...args),
  completeCheckout: ({ id, ...data }, ...args) =>
    post(`/api/v1/commerce/checkouts/${id}/complete`, data, ...args),
  getCheckoutConfirmation: ({ id, ...data }, ...args) =>
    get(`/api/v1/commerce/checkouts/${id}/confirmation`, data, ...args),
  getOrderHistory: (data, ...args) => get(`/api/v1/commerce/orders`, data, ...args),
  getOrderDetails: ({ id, ...data }, ...args) =>
    get(`/api/v1/commerce/orders/${id}`, data, ...args),
  getUnclaimedOrderHistory: (data, ...args) =>
    get(`/api/v1/commerce/orders/unclaimed`, data, ...args),
  updateOrderFulfillment: ({ orderId, ...data }, ...args) =>
    post(`/api/v1/commerce/orders/${orderId}/modify_fulfillment`, data, ...args),
  claimOrder: ({ orderId, ...data }, ...args) =>
    post(`/api/v1/commerce/orders/${orderId}/claim`, data, ...args),

  createBankAccount: (data, ...args) =>
    post(`/api/v1/payment_instruments/bank_accounts/create`, data, ...args),
  deleteBankAccount: (data, ...args) =>
    del(`/api/v1/payment_instruments/bank_accounts/${data.id}`, data, ...args),

  createCardStripe: (data, ...args) =>
    post(`/api/v1/payment_instruments/cards/create_stripe`, data, ...args),
  deleteCard: (data, ...args) =>
    del(`/api/v1/payment_instruments/cards/${data.id}`, data, ...args),

  createFundingPayment: (data, ...args) =>
    post(`/api/v1/payments/create_funding`, data, ...args),

  getPrivateAccounts: (data, ...args) =>
    get(`/api/v1/anon_proxy/vendor_accounts`, data, ...args),
  configurePrivateAccount: (data, ...args) =>
    post(`/api/v1/anon_proxy/vendor_accounts/${data.id}/configure`, data, ...args),
  makePrivateAccountAuthRequest: (data, ...args) =>
    post(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/make_auth_request`,
      data,
      ...args
    ),
  pollForNewPrivateAccountMagicLink: (data, opts) =>
    post(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/poll_for_new_magic_link`,
      data,
      opts
    ),

  getPreferencesPublic: (data, ...args) =>
    get("/api/v1/preferences/public", data, ...args),
  updatePreferencesPublic: (data, ...args) =>
    post("/api/v1/preferences/public", data, ...args),
  updatePreferences: (data, ...args) => post("/api/v1/preferences", data, ...args),

  completeSurvey: (data, ...args) => post(`/api/v1/surveys`, data, ...args),
};
