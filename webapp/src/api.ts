import config from "./config";
import { getCurrentLanguage } from "./localization/currentLanguage";
import apiBase from "./modules/apiBase";
import { AxiosRequestConfig, AxiosResponse } from "axios";
import axiosRetry, { isIdempotentRequestError, isNetworkError } from "axios-retry";

const instance = apiBase.create(config.apiHost, {
  debug: !!config.debug,
  chaos: Number(config.chaos || 0),
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

interface Params {
  [rest: string]: any;
}

export interface IdParams {
  id: number;
  [rest: string]: any;
}

interface OfferingIdParams {
  offeringId: number;
  [rest: string]: any;
}

interface OrderIdParams {
  orderId: number;
  [rest: string]: any;
}

interface LocaleFileParams {
  namespace: string;
  locale: string;
  [rest: string]: any;
}

instance.interceptors.request.use(
  (config) => {
    config.headers["Accept-Language"] = getCurrentLanguage();
    return config;
  },
  (error) => Promise.reject(error)
);

const get = <T = any, D = Params>(
  path: string,
  params?: D,
  opts?: AxiosRequestConfig
): Promise<AxiosResponse<T>> => {
  return instance.get(path, apiBase.mergeParams(params || {}, opts));
};
const post = <T = any, D = Params>(
  path: string,
  params?: D,
  opts?: AxiosRequestConfig
): Promise<AxiosResponse<T>> => {
  return instance.post(path, params, opts);
};
const patch = <T = any, D = Params>(
  path: string,
  params?: D,
  opts?: AxiosRequestConfig
): Promise<AxiosResponse<T>> => {
  return instance.patch(path, params, opts);
};

const put = <T = any, D = Params>(
  path: string,
  params?: D,
  opts?: AxiosRequestConfig
): Promise<AxiosResponse<T>> => {
  return instance.put(path, params, opts);
};

const del = <T = any, D = Params>(
  path: string,
  params?: D,
  opts?: AxiosRequestConfig
): Promise<AxiosResponse<T>> => {
  return instance.delete(path, apiBase.mergeParams(params || {}, opts));
};

export default {
  ...apiBase,
  axios: instance,
  get,
  post,
  patch,
  put,
  del,
  getMe: (data?: Params, config?: AxiosRequestConfig) =>
    get<CurrentMember>(`/api/v1/me`, data, config),
  updateMe: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>(`/api/v1/me/update`, data, config),
  onboard: (data?: Params, config?: AxiosRequestConfig) =>
    post<Onboarded>(`/api/v1/me/onboard`, data, config),
  changeLanguage: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>(`/api/v1/me/language`, data, config),
  getSupportedGeographies: (data?: Params, config?: AxiosRequestConfig) =>
    get<SupportedGeographies>(`/api/v1/meta/supported_geographies`, data, config),
  getSupportedLocales: (data?: Params, config?: AxiosRequestConfig) =>
    get<ApiCollection<Locale>>(`/api/v1/meta/supported_locales`, data, config),
  getSupportedCurrencies: (data?: Params, config?: AxiosRequestConfig) =>
    get<ApiCollection<Currency>>(`/api/v1/meta/supported_currencies`, data, config),
  getSupportedPaymentMethods: (data?: Params, config?: AxiosRequestConfig) =>
    get<ApiCollection<string>>(`/api/v1/meta/supported_payment_methods`, data, config),
  geolocateIp: (data?: Params, config?: AxiosRequestConfig) =>
    get<GeolocateIP>(`/api/v1/meta/geolocate_ip`, data, config),
  getSupportedOrganizations: (data?: Params, config?: AxiosRequestConfig) =>
    get(`/api/v1/meta/supported_organizations`, data, config),
  getLocaleFile: (
    { namespace, locale, ...data }: LocaleFileParams,
    config?: AxiosRequestConfig
  ) => get(`/api/v1/meta/static_strings/${locale}/${namespace}`, data, config),
  dashboard: (data?: Params, config?: AxiosRequestConfig) =>
    get<Dashboard>("/api/v1/me/dashboard", data, config),
  getLedgersOverview: (data?: Params, config?: AxiosRequestConfig) =>
    get<LedgersView>("/api/v1/ledgers/overview", data, config),
  getLedgerLines: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    get<LedgerLines>(`/api/v1/ledgers/${id}/lines`, data, config),
  authStart: (data?: Params, config?: AxiosRequestConfig) =>
    post<AuthFlowMember>(`/api/v1/auth/start`, data, config),
  authVerify: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>(`/api/v1/auth/verify`, data, config),
  authContactList: (data?: Params, config?: AxiosRequestConfig) =>
    post(`/api/v1/auth/contact_list`, data, config),
  authSignout: (data?: Params, config?: AxiosRequestConfig) =>
    del(`/api/v1/auth`, data, config),
  getMobilityMap: (data?: Params, config?: AxiosRequestConfig) =>
    get<MobilityMap>("/api/v1/mobility/map", data, config),
  getMobilityMapFeatures: (data?: Params, config?: AxiosRequestConfig) =>
    get<MobilityMapFeatures>("/api/v1/mobility/map_features", data, config),
  getMobilityVehicle: (data?: Params, config?: AxiosRequestConfig) =>
    get<MobilityDetailedVehicle>("/api/v1/mobility/vehicle", data, config),
  beginMobilityTrip: (data?: Params, config?: AxiosRequestConfig) =>
    post<MobilityTrip>("/api/v1/mobility/begin_trip", data, config),
  endMobilityTrip: (data?: Params, config?: AxiosRequestConfig) =>
    post<MobilityTrip>("/api/v1/mobility/end_trip", data, config),
  getMobilityTrips: (data?: Params, config?: AxiosRequestConfig) =>
    get<MobilityTripCollection>("/api/v1/mobility/trips", data, config),
  getUserAgent: () => get<UserAgent>("/api/useragent"),
  getCommerceOfferings: () => get<{ items: Offering[] }>("/api/v1/commerce/offerings"),
  getCommerceOfferingDetails: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    get<OfferingWithContext>(`/api/v1/commerce/offerings/${id}`, data, config),
  putCartItem: ({ offeringId, ...data }: OfferingIdParams, config?: AxiosRequestConfig) =>
    put<OfferingWithContext>(
      `/api/v1/commerce/offerings/${offeringId}/cart/item`,
      data,
      config
    ),
  startCheckout: (
    { offeringId, ...data }: OfferingIdParams,
    config?: AxiosRequestConfig
  ) => post<Checkout>(`/api/v1/commerce/offerings/${offeringId}/checkout`, data, config),
  getCheckout: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    get<Checkout>(`/api/v1/commerce/checkouts/${id}`, data, config),
  updateCheckoutFulfillment: (
    { checkoutId, ...data }: Params,
    config?: AxiosRequestConfig
  ) =>
    post<Checkout>(
      `/api/v1/commerce/checkouts/${checkoutId}/modify_fulfillment`,
      data,
      config
    ),
  completeCheckout: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    post<CheckoutConfirmation>(`/api/v1/commerce/checkouts/${id}/complete`, data, config),
  getCheckoutConfirmation: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    get<CheckoutConfirmation>(
      `/api/v1/commerce/checkouts/${id}/confirmation`,
      data,
      config
    ),
  getOrderHistory: (data?: Params, config?: AxiosRequestConfig) =>
    get<OrderHistoryCollection>(`/api/v1/commerce/orders`, data, config),
  getOrderDetails: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    get<DetailedOrderHistory>(`/api/v1/commerce/orders/${id}`, data, config),
  getUnclaimedOrderHistory: (data?: Params, config?: AxiosRequestConfig) =>
    get<UnclaimedOrderCollection>(`/api/v1/commerce/orders/unclaimed`, data, config),
  updateOrderFulfillment: (
    { orderId, ...data }: OrderIdParams,
    config?: AxiosRequestConfig
  ) =>
    post<DetailedOrderHistory>(
      `/api/v1/commerce/orders/${orderId}/modify_fulfillment`,
      data,
      config
    ),
  claimOrder: ({ orderId, ...data }: OrderIdParams, config?: AxiosRequestConfig) =>
    post<DetailedOrderHistory>(`/api/v1/commerce/orders/${orderId}/claim`, data, config),

  createBankAccount: (data?: Params, config?: AxiosRequestConfig) =>
    post<MutationPaymentInstrument>(
      `/api/v1/payment_instruments/bank_accounts/create`,
      data,
      config
    ),
  deleteBankAccount: (data: IdParams, config?: AxiosRequestConfig) =>
    del<MutationPaymentInstrument>(
      `/api/v1/payment_instruments/bank_accounts/${data.id}`,
      data,
      config
    ),

  createCardStripe: (data?: Params, config?: AxiosRequestConfig) =>
    post<MutationPaymentInstrument>(
      `/api/v1/payment_instruments/cards/create_stripe`,
      data,
      config
    ),
  deleteCard: (data: IdParams, config?: AxiosRequestConfig) =>
    del<MutationPaymentInstrument>(
      `/api/v1/payment_instruments/cards/${data.id}`,
      data,
      config
    ),

  createFundingPayment: (data?: Params, config?: AxiosRequestConfig) =>
    post<FundingTransaction>(`/api/v1/payments/create_funding`, data, config),
  chargeLedgerBalance: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>(`/api/v1/payments/charge_balance`, data, config),

  getPrivateAccounts: (data?: Params, config?: AxiosRequestConfig) =>
    get<{ items: AnonProxyVendorAccount[] }>(
      `/api/v1/anon_proxy/vendor_accounts`,
      data,
      config
    ),
  processPrivateAccountDetail: ({ id, ...data }: IdParams, config?: AxiosRequestConfig) =>
    post<AnonProxyVendorAccount>(
      `/api/v1/anon_proxy/vendor_accounts/${id}/process`,
      data,
      config
    ),
  makePrivateAccountAuthRequest: (data: IdParams, config?: AxiosRequestConfig) =>
    post<AnonProxyVendorAccount>(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/make_auth_request`,
      data,
      config
    ),
  pollForNewPrivateAccountMagicLink: (data: IdParams, opts?: AxiosRequestConfig) =>
    post<AnonProxyVendorAccountPollResult>(
      `/api/v1/anon_proxy/vendor_accounts/${data.id}/poll_for_new_magic_link`,
      data,
      opts
    ),

  getPreferencesPublic: (data?: Params, config?: AxiosRequestConfig) =>
    get<PublicPrefsMember>("/api/v1/preferences/public", data, config),
  updatePreferencesPublic: (data?: Params, config?: AxiosRequestConfig) =>
    post<PublicPrefsMember>("/api/v1/preferences/public", data, config),
  updatePreferences: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>("/api/v1/preferences", data, config),

  supportRegainAccountAccess: (data?: Params, config?: AxiosRequestConfig) =>
    post("/api/v1/support/regain_account_access", data, config),

  completeSurvey: (data?: Params, config?: AxiosRequestConfig) =>
    post<CurrentMember>(`/api/v1/surveys`, data, config),
};
