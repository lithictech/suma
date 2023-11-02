import config from "./config";
import relativeLink from "./modules/relativeLink";
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
const postForm = (path, params, opts) => {
  return instance.postForm(path, params, opts);
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

function followRedirect(navigate) {
  return function (resp) {
    if (resp.headers["created-resource-admin"]) {
      const [href, relative] = relativeLink(resp.headers["created-resource-admin"]);
      if (relative) {
        navigate(href);
      } else {
        window.location.href = href;
      }
    }
    return resp;
  };
}

export default {
  ...apiBase,
  followRedirect,
  get,
  post,
  postForm,
  patch,
  put,
  del,
  signOut: () => del("/adminapi/v1/auth"),
  signIn: (data) => post("/adminapi/v1/auth", data),
  getCurrentUser: (data) => get(`/adminapi/v1/auth`, data),
  impersonate: ({ id, ...data }) => post(`/adminapi/v1/auth/impersonate/${id}`, data),
  unimpersonate: (data) => del(`/adminapi/v1/auth/impersonate`, data),
  getCurrencies: (data) => get(`/adminapi/v1/meta/currencies`, data),
  getSupportedGeographies: (data) => get(`/adminapi/v1/meta/geographies`, data),
  getVendorServiceCategories: (data) =>
    get(`/adminapi/v1/meta/vendor_service_categories`, data),
  getEligibilityConstraintsMeta: (data) =>
    get(`/adminapi/v1/meta/eligibility_constraints`, data),
  getEligibilityConstraints: (data) => get(`/adminapi/v1/constraints`, data),
  getEligibilityConstraint: ({ id, ...data }) =>
    get(`/adminapi/v1/constraints/${id}`, data),
  createEligibilityConstraint: (data) => post(`/adminapi/v1/constraints/create`, data),

  getBankAccount: ({ id, ...data }) => get(`/adminapi/v1/bank_accounts/${id}`, data),

  getBookTransactions: (data) => get(`/adminapi/v1/book_transactions`, data),
  getBookTransaction: ({ id, ...data }) =>
    get(`/adminapi/v1/book_transactions/${id}`, data),
  createBookTransaction: (data) => post(`/adminapi/v1/book_transactions/create`, data),

  getFundingTransactions: (data) => get(`/adminapi/v1/funding_transactions`, data),
  getFundingTransaction: ({ id, ...data }) =>
    get(`/adminapi/v1/funding_transactions/${id}`, data),
  createForSelfFundingTransaction: (data) =>
    post(`/adminapi/v1/funding_transactions/create_for_self`, data),
  getPayoutTransactions: (data) => get(`/adminapi/v1/payout_transactions`, data),
  getPayoutTransaction: ({ id, ...data }) =>
    get(`/adminapi/v1/payout_transactions/${id}`, data),

  getCommerceOfferings: (data) => get("/adminapi/v1/commerce_offerings", data),
  getCommerceOffering: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_offerings/${id}`, data),
  createCommerceOffering: (data) =>
    postForm("/adminapi/v1/commerce_offerings/create", data),
  getCommerceOfferingPickList: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_offerings/${id}/picklist`, data),

  getCommerceProducts: (data) => get("/adminapi/v1/commerce_products", data),
  getCommerceProduct: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_products/${id}`, data),

  getVendors: (data) => get(`/adminapi/v1/vendors`, data),

  getCommerceOrders: (data) => get(`/adminapi/v1/commerce_orders`, data),
  getCommerceOrder: ({ id, ...data }) => get(`/adminapi/v1/commerce_orders/${id}`, data),

  getMessageDeliveries: (data) => get(`/adminapi/v1/message_deliveries`, data),
  getMessageDelivery: ({ id, ...data }) =>
    get(`/adminapi/v1/message_deliveries/${id}`, data),

  getMembers: (data) => get(`/adminapi/v1/members`, data),
  getMember: ({ id, ...data }) => get(`/adminapi/v1/members/${id}`, data),
  updateMember: ({ id, ...data }) => post(`/adminapi/v1/members/${id}`, data),
  changeMemberEligibility: ({ id, ...data }) =>
    post(`/adminapi/v1/members/${id}/eligibilities`, data),

  searchPaymentInstruments: (data) =>
    post(`/adminapi/v1/search/payment_instruments`, data),
  searchLedgers: (data) => post(`/adminapi/v1/search/ledgers`, data),
  searchLedgersLookup: (data) => post(`/adminapi/v1/search/ledgers/lookup`, data),
  searchTranslations: (data) => post(`/adminapi/v1/search/translations`, data),

  /**
   * Return an API url.
   * @param tail {string}
   * @param params {object}
   * @return {URL}
   */
  makeUrl: (tail, params) => {
    const origin = config.apiHost || window.location.origin;
    const u = new URL(origin + tail);
    Object.entries(params).forEach(
      ([k, v]) => v !== null && v !== undefined && u.searchParams.set(k, "" + v)
    );
    return u;
  },
};
