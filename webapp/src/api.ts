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
      (SAFE_HTTP_METHODS.includes(error.config?.method || "") &&
        error.code === "ECONNABORTED")
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

const get = (path: string, params?: any, opts?: any): any => {
  return instance.get(path, apiBase.mergeParams(params, opts));
};
const post = (path: string, params?: any, opts?: any): any => {
  return instance.post(path, params, opts);
};
const patch = (path: string, params?: any, opts?: any): any => {
  return instance.patch(path, params, opts);
};

const put = (path: string, params?: any, opts?: any): any => {
  return instance.put(path, params, opts);
};

const del = (path: string, params?: any, opts?: any): any => {
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
  getMe: (data?: any, ...args: any[]) => get(`/api/v1/me`, data, ...args),
  updateMe: (data?: any, ...args: any[]) => post(`/api/v1/me/update`, data, ...args),
  changeLanguage: (data?: any, ...args: any[]) =>
    post(`/api/v1/me/language`, data, ...args),
  getSupportedGeographies: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/supported_geographies`, data, ...args),
  getSupportedLocales: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/supported_locales`, data, ...args),
  getSupportedCurrencies: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/supported_currencies`, data, ...args),
  getSupportedPaymentMethods: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/supported_payment_methods`, data, ...args),
  geolocateIp: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/geolocate_ip`, data, ...args),
  getSupportedOrganizations: (data?: any, ...args: any[]) =>
    get(`/api/v1/meta/supported_organizations`, data, ...args),
  getLocaleFile: ({ namespace, locale, ...data }: any, ...args: any[]) =>
    get(`/api/v1/meta/static_strings/${locale}/${namespace}`, data, ...args),
  dashboard: (data?: any, ...args: any[]) => get("/api/v1/me/dashboard", data, ...args),
  getLedgersOverview: (data?: any, ...args: any[]) =>
    get("/api/v1/ledgers/overview", data, ...args),
  getLedgerLines: ({ id, ...data }: any, ...args: any[]) =>
    get(`/api/v1/ledgers/${id}/lines`, data, ...args),
  authStart: (data?: any, ...args: any[]) => post(`/api/v1/auth/start`, data, ...args),
  authVerify: (data?: any, ...args: any[]) => post(`/api/v1/auth/verify`, data, ...args),
  authContactList: (data?: any, ...args: any[]) =>
    post(`/api/v1/auth/contact_list`, data, ...args),
  authSignout: (data?: any, ...args: any[]) => del(`/api/v1/auth`, data, ...args),
  getMobilityMap: (data?: any, ...args: any[]) =>
    get("/api/v1/mobility/map", data, ...args),
  getMobilityMapFeatures: (data?: any, ...args: any[]) =>
    get("/api/v1/mobility/map_features", data, ...args),
  getMobilityVehicle: (data?: any, ...args: any[]) =>
    get("/api/v1/mobility/vehicle", data, ...args),
  beginMobilityTrip: (data?: any, ...args: any[]) =>
    post("/api/v1/mobility/begin_trip", data, ...args),
  endMobilityTrip: (data?: any, ...args: any[]) =>
    post("/api/v1/mobility/end_trip", data, ...args),
  getMobilityTrips: (data?: any, ...args: any[]) =>
    get("/api/v1/mobility/trips", data, ...args),
  getUserAgent: () => get("/api/useragent"),
  getCommerceOfferings: () => get("/api/v1/commerce/offerings"),
  getCommerceOfferingDetails: ({ id, ...data }: any, ...args: any[]) =>
    get(`/api/v1/commerce/offerings/${id}`, data, ...args),
  putCartItem: ({ offeringId, ...data }: any, ...args: any[]) =>
    put(`/api/v1/commerce/offerings/${offeringId}/cart/item`, data, ...args),
  startCheckout: ({ offeringId, ...data }: any, ...args: any[]) =>
    post(`/api/v1/commerce/offerings/${offeringId}/checkout`, data, ...args),
  getCheckout: ({ id, ...data }: any, ...args: any[]) =>
    get(`/api/v1/commerce/checkouts/${id}`, data, ...args),
  updateCheckoutFulfillment: ({ checkoutId, ...data }: any, ...args: any[]) =>
    post(`/api/v1/commerce/checkouts/${checkoutId}/modify_fulfillment`, data, ...args),
  completeCheckout: ({ id, ...data }: any, ...args: any[]) =>
    post(`/api/v1/commerce/checkouts/${id}/complete`, data, ...args),
  getCheckoutConfirmation: ({ id, ...data }: any, ...args: any[]) =>
    get(`/api/v1/commerce/checkouts/${id}/confirmation`, data, ...args),
  getOrderHistory: (data?: any, ...args: any[]) =>
    get(`/api/v1/commerce/orders`, data, ...args),
  getOrderDetails: ({ id, ...data }: any, ...args: any[]) =>
    get(`/api/v1/commerce/orders/${id}`, data, ...args),
  getUnclaimedOrderHistory: (data?: any, ...args: any[]) =>
    get(`/api/v1/commerce/orders/unclaimed`, data, ...args),
  updateOrderFulfillment: ({ orderId, ...data }: any, ...args: any[]) =>
    post(`/api/v1/commerce/orders/${orderId}/modify_fulfillment`, data, ...args),
  claimOrder: ({ orderId, ...data }: any, ...args: any[]) =>
    post(`/api/v1/commerce/orders/${orderId}/claim`, data, ...args),

  createBankAccount: (data?: any, ...args: any[]) =>
    post(`/api/v1/payment_instruments/bank_accounts/create`, data, ...args),
  deleteBankAccount: (data?: any, ...args: any[]) =>
    del(`/api/v1/payment_instruments/bank_accounts/${data.id}`, data, ...args),

  createCardStripe: (data?: any, ...args: any[]) =>
    post(`/api/v1/payment_instruments/cards/create_stripe`, data, ...args),
  deleteCard: (data?: any, ...args: any[]) =>
    del(`/api/v1/payment_instruments/cards/${data.id}`, data, ...args),

  createFundingPayment: (data?: any, ...args: any[]) =>
    post(`/api/v1/payments/create_funding`, data, ...args),
  chargeLedgerBalance: (data?: any, ...args: any[]) =>
    post(`/api/v1/payments/charge_balance`, data, ...args),

  getPrivateAccounts: (data?: any, ...args: any[]) =>
    get(`/api/v1/anon_proxy/vendor_accounts`, data, ...args),
  processPrivateAccountDetail: ({ id, ...data }: any, ...args: any[]) =>
    post(`/api/v1/anon_proxy/vendor_accounts/${id}/process`, data, ...args),
  makePrivateAccountAuthRequest: (data?: any, ...args: any[]) =>
    post(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/make_auth_request`,
      data,
      ...args
    ),
  pollForNewPrivateAccountMagicLink: (data?: any, opts?: any) =>
    post(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/poll_for_new_magic_link`,
      data,
      opts
    ),

  getPreferencesPublic: (data?: any, ...args: any[]) =>
    get("/api/v1/preferences/public", data, ...args),
  updatePreferencesPublic: (data?: any, ...args: any[]) =>
    post("/api/v1/preferences/public", data, ...args),
  updatePreferences: (data?: any, ...args: any[]) =>
    post("/api/v1/preferences", data, ...args),

  supportRegainAccountAccess: (data?: any, ...args: any[]) =>
    post("/api/v1/support/regain_account_access", data, ...args),

  completeSurvey: (data?: any, ...args: any[]) => post(`/api/v1/surveys`, data, ...args),
};
