import config from "./config";
import { getCurrentLanguage } from "./localization/currentLanguage";
import apiBase from "./shared/apiBase";

const instance = apiBase.create(config.apiHost, {
  debug: config.debug,
  chaos: false,
});

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
  getMe: (data) => get(`/api/v1/me`, data),
  updateMe: (data) => post(`/api/v1/me/update`, data),
  changeLanguage: (data) => post(`/api/v1/me/language`, data),
  joinWaitlist: (data) => post(`/api/v1/me/waitlist`, data),
  getSupportedGeographies: (data) => get(`/api/v1/meta/supported_geographies`, data),
  getSupportedLocales: (data) => get(`/api/v1/meta/supported_locales`, data),
  getSupportedCurrencies: (data) => get(`/api/v1/meta/supported_currencies`, data),
  getSupportedPaymentMethods: (data) =>
    get(`/api/v1/meta/supported_payment_methods`, data),
  geolocateIp: (data) => get(`/api/v1/meta/geolocate_ip`, data),
  dashboard: (data) => get("/api/v1/me/dashboard", data),
  getLedgersOverview: (data) => get("/api/v1/ledgers/overview", data),
  getLedgerLines: ({ id, ...data }) => get(`/api/v1/ledgers/${id}/lines`, data),
  authStart: (data) => post(`/api/v1/auth/start`, data),
  authVerify: (data) => post(`/api/v1/auth/verify`, data),
  authContactList: (data) => post(`/api/v1/auth/contact_list`, data),
  authSignout: (data) => del(`/api/v1/auth`, data),
  getMobilityMap: (data) => get("/api/v1/mobility/map", data),
  getMobilityMapFeatures: (data) => get("/api/v1/mobility/map_features", data),
  getMobilityVehicle: (data) => get("/api/v1/mobility/vehicle", data),
  beginMobilityTrip: (data) => post("/api/v1/mobility/begin_trip", data),
  endMobilityTrip: (data) => post("/api/v1/mobility/end_trip", data),
  getUserAgent: () => get("/api/useragent"),
  getCommerceOfferings: () => get("/api/v1/commerce/offerings"),
  getCommerceOfferingDetails: ({ id, ...data }) =>
    get(`/api/v1/commerce/offerings/${id}`, data),
  putCartItem: ({ offeringId, ...data }) =>
    put(`/api/v1/commerce/offerings/${offeringId}/cart/item`, data),
  startCheckout: ({ offeringId, ...data }) =>
    post(`/api/v1/commerce/offerings/${offeringId}/checkout`, data),
  getCheckout: ({ id, ...data }) => get(`/api/v1/commerce/checkouts/${id}`, data),
  completeCheckout: ({ id, ...data }) =>
    post(`/api/v1/commerce/checkouts/${id}/complete`, data),
  getCheckoutConfirmation: ({ id, ...data }) =>
    get(`/api/v1/commerce/checkouts/${id}/confirmation`, data),
  getOrderHistory: (data) => get(`/api/v1/commerce/orders`, data),
  getOrderDetails: ({ id, ...data }) => get(`/api/v1/commerce/orders/${id}`, data),
  getUnclaimedOrderHistory: (data) => get(`/api/v1/commerce/orders/unclaimed`, data),
  updateOrderFulfillment: ({ orderId, ...data }) =>
    post(`/api/v1/commerce/orders/${orderId}/modify_fulfillment`, data),
  claimOrder: ({ orderId, ...data }) =>
    post(`/api/v1/commerce/orders/${orderId}/claim`, data),

  createBankAccount: (data) =>
    post(`/api/v1/payment_instruments/bank_accounts/create`, data),
  deleteBankAccount: (data) =>
    del(`/api/v1/payment_instruments/bank_accounts/${data.id}`, data),

  createCardStripe: (data) =>
    post(`/api/v1/payment_instruments/cards/create_stripe`, data),
  deleteCard: (data) => del(`/api/v1/payment_instruments/cards/${data.id}`, data),

  createFundingPayment: (data) => post(`/api/v1/payments/create_funding`, data),

  getPrivateAccounts: (data) => get(`/api/v1/anon_proxy/vendor_accounts`, data),
  configurePrivateAccount: (data) =>
    post(`/api/v1/anon_proxy/vendor_accounts/${data.id}/configure`, data),
  makePrivateAccountAuthRequest: (data) =>
    post(`/api/v1/anon_proxy/vendor_accounts/${data.id}/make_auth_request`, data),
  pollForNewPrivateAccountMagicLink: (data, opts) =>
    post(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/poll_for_new_magic_link`,
      data,
      opts
    ),
};
