import config from "./config";
import relativeLink from "./modules/relativeLink";
import apiBase from "./shared/apiBase";
import isArray from "lodash/isArray";
import transform from "lodash/transform";

const instance = apiBase.create(config.apiHost, {
  debug: config.debug,
  chaos: config.chaos,
  formSerializer: {
    visitor: (value, key, path, helpers) => {
      if (value === null) {
        // See postForm below
        value = "";
      }
      return helpers.defaultVisitor.apply(this, [value, key, path, helpers]);
    },
  },
});

const get = (path, params, opts) => {
  return instance.get(path, apiBase.mergeParams(params, opts));
};
const post = (path, params, opts) => {
  return instance.post(path, params, opts);
};
const postForm = (path, params, opts) => {
  const paramsUsingStrippedValues = transform(params, (result, value, key) => {
    // null gets stripped out of the form data, so we can end up with an empty form data body, which is an error.
    // We only need to worry about this at the top level- if a nested object field is null,
    // it'll get converted to empty string in visitor (or automatically by axios).
    // Axios form serialization is finnicky so there's a good change this code
    // will be incorrect in a future upgrade.
    result[key] = value === null ? "" : value;
    // If an array is empty, it can't be submitted in the multipart form because there are no items to submit.
    // See https://axios-http.com/docs/multipart;
    // for example,we can't do `formData.append('arr2[0]', '1');`, because arr2 is empty.
    // In this case, add a special <key>_doemptyarray key to the form;
    // the API endpoints look for this special key and will empty-out the array if present.
    if (isArray(value) && value.length === 0) {
      result[`${key}_doemptyarray`] = true;
    }
  });
  return instance.postForm(path, paramsUsingStrippedValues, opts);
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
    if (resp && resp.headers && resp.headers["created-resource-admin"]) {
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
  getResourceAccessMeta: (data) => get(`/adminapi/v1/meta/resource_access`, data),

  getEligibilityConstraints: (data) => get(`/adminapi/v1/eligibility_constraints`, data),
  createEligibilityConstraint: (data) =>
    post(`/adminapi/v1/eligibility_constraints/create`, data),
  getEligibilityConstraint: ({ id, ...data }) =>
    get(`/adminapi/v1/eligibility_constraints/${id}`, data),
  updateEligibilityConstraint: ({ id, ...data }) =>
    post(`/adminapi/v1/eligibility_constraints/${id}`, data),

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

  getPaymentLedgers: (data) => get(`/adminapi/v1/payment_ledgers`, data),
  getPaymentLedger: ({ id, ...data }) => get(`/adminapi/v1/payment_ledgers/${id}`, data),

  getPaymentTriggers: (data) => get(`/adminapi/v1/payment_triggers`, data),
  createPaymentTrigger: (data) => post(`/adminapi/v1/payment_triggers/create`, data),
  getPaymentTrigger: ({ id, ...data }) =>
    get(`/adminapi/v1/payment_triggers/${id}`, data),
  updatePaymentTrigger: ({ id, ...data }) =>
    post(`/adminapi/v1/payment_triggers/${id}`, data),

  getCommerceOfferings: (data) => get("/adminapi/v1/commerce_offerings", data),
  getCommerceOffering: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_offerings/${id}`, data),
  createCommerceOffering: (data) =>
    postForm("/adminapi/v1/commerce_offerings/create", data),
  updateCommerceOffering: ({ id, ...data }) =>
    postForm(`/adminapi/v1/commerce_offerings/${id}`, data),
  updateOfferingEligibilityConstraints: ({ id, ...data }) =>
    post(`/adminapi/v1/commerce_offerings/${id}/eligibilities`, data),
  getCommerceOfferingPickList: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_offerings/${id}/picklist`, data),

  getCommerceProducts: (data) => get("/adminapi/v1/commerce_products", data),
  createCommerceProduct: (data) =>
    postForm("/adminapi/v1/commerce_products/create", data),
  getCommerceProduct: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_products/${id}`, data),
  updateCommerceProduct: ({ id, ...data }) =>
    postForm(`/adminapi/v1/commerce_products/${id}`, data),

  createCommerceOfferingProduct: (data) =>
    postForm("/adminapi/v1/commerce_offering_products/create", data),
  getCommerceOfferingProduct: ({ id, ...data }) =>
    get(`/adminapi/v1/commerce_offering_products/${id}`, data),
  updateCommerceOfferingProduct: ({ id, ...data }) =>
    post(`/adminapi/v1/commerce_offering_products/${id}`, data),

  getVendors: (data) => get(`/adminapi/v1/vendors`, data),
  createVendor: (data) => postForm("/adminapi/v1/vendors/create", data),
  getVendor: ({ id, ...data }) => get(`/adminapi/v1/vendors/${id}`, data),
  updateVendor: ({ id, ...data }) => postForm(`/adminapi/v1/vendors/${id}`, data),

  getVendibleGroups: (data) => get(`/adminapi/v1/vendible_groups`, data),
  createVendibleGroup: (data) => post("/adminapi/v1/vendible_groups/create", data),
  getVendibleGroup: ({ id, ...data }) => get(`/adminapi/v1/vendible_groups/${id}`, data),
  updateVendibleGroup: ({ id, ...data }) =>
    post(`/adminapi/v1/vendible_groups/${id}`, data),

  getVendorServices: (data) => get(`/adminapi/v1/vendor_services`, data),
  getVendorService: ({ id, ...data }) => get(`/adminapi/v1/vendor_services/${id}`, data),
  updateVendorService: ({ id, ...data }) =>
    postForm(`/adminapi/v1/vendor_services/${id}`, data),
  updateVendorServiceEligibilityConstraints: ({ id, ...data }) =>
    post(`/adminapi/v1/vendor_services/${id}/eligibilities`, data),

  getVendorAccounts: (data) => get("/adminapi/v1/anon_proxy/vendor_accounts", data),
  getVendorAccount: ({ id, data }) =>
    get(`/adminapi/v1/anon_proxy/vendor_accounts/${id}`, data),

  getVendorConfigurations: (data) =>
    get("/adminapi/v1/anon_proxy/vendor_configurations", data),
  getVendorConfiguration: ({ id, data }) =>
    get(`/adminapi/v1/anon_proxy/vendor_configurations/${id}`, data),
  updateVendorConfigurationEligibilityConstraints: ({ id, ...data }) =>
    post(`/adminapi/v1/anon_proxy/vendor_configurations/${id}/eligibilities`, data),

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

  getOrganizations: (data) => get(`/adminapi/v1/organizations`, data),
  getOrganization: ({ id }) => get(`/adminapi/v1/organizations/${id}`),
  createOrganization: (data) => post("/adminapi/v1/organizations/create", data),
  updateOrganization: ({ id, ...data }) => post(`/adminapi/v1/organizations/${id}`, data),

  getOrganizationMemberships: (data) =>
    get(`/adminapi/v1/organization_memberships`, data),
  getOrganizationMembership: ({ id }) =>
    get(`/adminapi/v1/organization_memberships/${id}`),
  createOrganizationMembership: (data) =>
    post("/adminapi/v1/organization_memberships/create", data),
  updateOrganizationMembership: ({ id, ...data }) =>
    post(`/adminapi/v1/organization_memberships/${id}`, data),

  getRoles: (data) => get("/adminapi/v1/roles", data),

  searchProducts: (data) => post(`/adminapi/v1/search/products`, data),
  searchOfferings: (data) => post(`/adminapi/v1/search/offerings`, data),
  searchPaymentInstruments: (data) =>
    post(`/adminapi/v1/search/payment_instruments`, data),
  searchLedgers: (data) => post(`/adminapi/v1/search/ledgers`, data),
  searchLedgersLookup: (data) => post(`/adminapi/v1/search/ledgers/lookup`, data),
  searchTranslations: (data) => post(`/adminapi/v1/search/translations`, data),
  searchVendors: (data) => post(`/adminapi/v1/search/vendors`, data),
  searchMembers: (data) => post(`/adminapi/v1/search/members`, data),
  searchOrganizations: (data) => post(`/adminapi/v1/search/organizations`, data),
  searchVendorServices: (data) => post(`/adminapi/v1/search/vendor_services`, data),
  searchCommerceOffering: (data) => post(`/adminapi/v1/search/commerce_offerings`, data),

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
