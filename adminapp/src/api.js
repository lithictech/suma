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
        return null;
      } else {
        window.location.href = href;
        return null;
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
  signIn: (data, ...args) => post("/adminapi/v1/auth", data, ...args),
  getCurrentUser: (data, ...args) => get(`/adminapi/v1/auth`, data, ...args),
  impersonate: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/auth/impersonate/${id}`, data, ...args),
  unimpersonate: (data, ...args) => del(`/adminapi/v1/auth/impersonate`, data, ...args),
  getCurrencies: (data, ...args) => get(`/adminapi/v1/meta/currencies`, data, ...args),
  getSupportedGeographies: (data, ...args) =>
    get(`/adminapi/v1/meta/geographies`, data, ...args),
  getVendorServiceCategories: (data, ...args) =>
    get(`/adminapi/v1/meta/vendor_service_categories`, data, ...args),
  getProgramsMeta: (data, ...args) => get(`/adminapi/v1/meta/programs`, data, ...args),
  getResourceAccessMeta: (data, ...args) =>
    get(`/adminapi/v1/meta/resource_access`, data, ...args),
  getStateMachine: ({ name, ...data }, ...args) =>
    get(`/adminapi/v1/meta/state_machines/${name}`, data, ...args),

  getBankAccount: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/bank_accounts/${id}`, data, ...args),

  getBookTransactions: (data, ...args) =>
    get(`/adminapi/v1/book_transactions`, data, ...args),
  getBookTransaction: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/book_transactions/${id}`, data, ...args),
  createBookTransaction: (data, ...args) =>
    post(`/adminapi/v1/book_transactions/create`, data, ...args),

  getFundingTransactions: (data, ...args) =>
    get(`/adminapi/v1/funding_transactions`, data, ...args),
  getFundingTransaction: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/funding_transactions/${id}`, data, ...args),
  createForSelfFundingTransaction: (data, ...args) =>
    post(`/adminapi/v1/funding_transactions/create_for_self`, data, ...args),
  refundFundingTransaction: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/funding_transactions/${id}/refund`, data, ...args),
  getPayoutTransactions: (data, ...args) =>
    get(`/adminapi/v1/payout_transactions`, data, ...args),
  getPayoutTransaction: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/payout_transactions/${id}`, data, ...args),

  createOffPlatformTransaction: (...args) =>
    post(`/adminapi/v1/off_platform_transactions/create`, ...args),
  getOffPlatformTransaction: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/off_platform_transactions/${id}`, data, ...args),
  updateOffPlatformTransaction: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/off_platform_transactions/${id}`, data, ...args),

  getCharges: (data, ...args) => get(`/adminapi/v1/charges`, data, ...args),
  getCharge: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/charges/${id}`, data, ...args),

  getPaymentLedgers: (data, ...args) =>
    get(`/adminapi/v1/payment_ledgers`, data, ...args),
  getPaymentLedger: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/payment_ledgers/${id}`, data, ...args),

  getPaymentTriggers: (data, ...args) =>
    get(`/adminapi/v1/payment_triggers`, data, ...args),
  createPaymentTrigger: (data, ...args) =>
    post(`/adminapi/v1/payment_triggers/create`, data, ...args),
  getPaymentTrigger: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/payment_triggers/${id}`, data, ...args),
  updatePaymentTrigger: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/payment_triggers/${id}`, data, ...args),
  updatePaymentTriggerPrograms: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/payment_triggers/${id}/programs`, data, ...args),
  subdividePaymentTrigger: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/payment_triggers/${id}/subdivide`, data, ...args),

  getCommerceOfferings: (data, ...args) =>
    get("/adminapi/v1/commerce_offerings", data, ...args),
  getCommerceOffering: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/commerce_offerings/${id}`, data, ...args),
  createCommerceOffering: (data, ...args) =>
    postForm("/adminapi/v1/commerce_offerings/create", data, ...args),
  updateCommerceOffering: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/commerce_offerings/${id}`, data, ...args),
  updateOfferingPrograms: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/commerce_offerings/${id}/programs`, data, ...args),
  getCommerceOfferingPickList: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/commerce_offerings/${id}/picklist`, data, ...args),

  getCommerceProducts: (data, ...args) =>
    get("/adminapi/v1/commerce_products", data, ...args),
  createCommerceProduct: (data, ...args) =>
    postForm("/adminapi/v1/commerce_products/create", data, ...args),
  getCommerceProduct: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/commerce_products/${id}`, data, ...args),
  updateCommerceProduct: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/commerce_products/${id}`, data, ...args),

  createCommerceOfferingProduct: (data, ...args) =>
    postForm("/adminapi/v1/commerce_offering_products/create", data, ...args),
  getCommerceOfferingProduct: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/commerce_offering_products/${id}`, data, ...args),
  updateCommerceOfferingProduct: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/commerce_offering_products/${id}`, data, ...args),

  getVendors: (data, ...args) => get(`/adminapi/v1/vendors`, data, ...args),
  createVendor: (data, ...args) => postForm("/adminapi/v1/vendors/create", data, ...args),
  getVendor: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/vendors/${id}`, data, ...args),
  updateVendor: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/vendors/${id}`, data, ...args),

  getMarketingLists: (data, ...args) =>
    get(`/adminapi/v1/marketing_lists`, data, ...args),
  createMarketingList: (data, ...args) =>
    post("/adminapi/v1/marketing_lists/create", data, ...args),
  getMarketingList: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/marketing_lists/${id}`, data, ...args),
  updateMarketingList: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/marketing_lists/${id}`, data, ...args),

  getMarketingSmsBroadcasts: (data, ...args) =>
    get(`/adminapi/v1/marketing_sms_broadcasts`, data, ...args),
  createMarketingSmsBroadcast: (data, ...args) =>
    post("/adminapi/v1/marketing_sms_broadcasts/create", data, ...args),
  getMarketingSmsBroadcast: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/marketing_sms_broadcasts/${id}`, data, ...args),
  updateMarketingSmsBroadcast: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/marketing_sms_broadcasts/${id}`, data, ...args),
  sendMarketingSmsBroadcast: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/marketing_sms_broadcasts/${id}/send`, data, ...args),
  previewMarketingSmsBroadcast: (data, ...args) =>
    post(`/adminapi/v1/marketing_sms_broadcasts/preview`, data, ...args),
  getMarketingSmsBroadcastReview: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/marketing_sms_broadcasts/${id}/review`, data, ...args),

  getMarketingSmsDispatches: (data, ...args) =>
    get(`/adminapi/v1/marketing_sms_dispatches`, data, ...args),
  getMarketingSmsDispatch: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/marketing_sms_dispatches/${id}`, data, ...args),
  cancelMarketingSmsDispatch: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/marketing_sms_dispatches/${id}/cancel`, data, ...args),

  getPrograms: (data, ...args) => get(`/adminapi/v1/programs`, data, ...args),
  createProgram: (data, ...args) =>
    postForm("/adminapi/v1/programs/create", data, ...args),
  getProgram: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/programs/${id}`, data, ...args),
  updateProgram: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/programs/${id}`, data, ...args),

  getProgramEnrollments: (data, ...args) =>
    get(`/adminapi/v1/program_enrollments`, data, ...args),
  createProgramEnrollment: (data, ...args) =>
    post("/adminapi/v1/program_enrollments/create", data, ...args),
  getProgramEnrollment: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/program_enrollments/${id}`, data, ...args),
  updateProgramEnrollment: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/program_enrollments/${id}`, data, ...args),

  createProgramEnrollmentExclusion: (data, ...args) =>
    post("/adminapi/v1/program_enrollment_exclusions/create", data, ...args),
  getProgramEnrollmentExclusion: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/program_enrollment_exclusions/${id}`, data, ...args),
  destroyProgramEnrollmentExclusion: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/program_enrollment_exclusions/${id}/destroy`, data, ...args),

  createProgramPricing: (data, ...args) =>
    post("/adminapi/v1/program_pricings/create", data, ...args),
  getProgramPricing: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/program_pricings/${id}`, data, ...args),
  updateProgramPricing: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/program_pricings/${id}`, data, ...args),
  destroyProgramPricing: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/program_pricings/${id}/destroy`, data, ...args),

  getVendorServices: (data, ...args) =>
    get(`/adminapi/v1/vendor_services`, data, ...args),
  getVendorService: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/vendor_services/${id}`, data, ...args),
  createVendorService: (data, ...args) =>
    postForm(`/adminapi/v1/vendor_services/create`, data, ...args),
  updateVendorService: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/vendor_services/${id}`, data, ...args),

  getVendorServiceRates: (data, ...args) =>
    get(`/adminapi/v1/vendor_service_rates`, data, ...args),
  getVendorServiceRate: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/vendor_service_rates/${id}`, data, ...args),
  createVendorServiceRate: (data, ...args) =>
    post(`/adminapi/v1/vendor_service_rates/create`, data, ...args),
  updateVendorServiceRate: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/vendor_service_rates/${id}`, data, ...args),

  getVendorAccounts: (data, ...args) =>
    get("/adminapi/v1/anon_proxy_vendor_accounts", data, ...args),
  getVendorAccount: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/anon_proxy_vendor_accounts/${id}`, data, ...args),
  destroyVendorAccount: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/anon_proxy_vendor_accounts/${id}/destroy`, data, ...args),

  getVendorConfigurations: (data, ...args) =>
    get("/adminapi/v1/anon_proxy_vendor_configurations", data, ...args),
  getVendorConfiguration: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/anon_proxy_vendor_configurations/${id}`, data, ...args),
  updateVendorConfiguration: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/anon_proxy_vendor_configurations/${id}`, data, ...args),
  updateVendorConfigurationPrograms: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/anon_proxy_vendor_configurations/${id}/programs`, data, ...args),

  getAnonMemberContacts: (data, ...args) =>
    get(`/adminapi/v1/anon_proxy_member_contacts`, data, ...args),
  provisionAnonMemberContact: (data, ...args) =>
    post("/adminapi/v1/anon_proxy_member_contacts/provision", data, ...args),
  getAnonMemberContact: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/anon_proxy_member_contacts/${id}`, data, ...args),
  updateAnonMemberContact: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/anon_proxy_member_contacts/${id}`, data, ...args),
  destroyMemberContact: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/anon_proxy_member_contacts/${id}/destroy`, data, ...args),

  getCommerceOrders: (data, ...args) =>
    get(`/adminapi/v1/commerce_orders`, data, ...args),
  getCommerceOrder: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/commerce_orders/${id}`, data, ...args),

  getMessageDeliveries: (data, ...args) =>
    get(`/adminapi/v1/message_deliveries`, data, ...args),
  getMessageDelivery: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/message_deliveries/${id}`, data, ...args),

  getMembers: (data, ...args) => get(`/adminapi/v1/members`, data, ...args),
  getMember: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/members/${id}`, data, ...args),
  updateMember: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/members/${id}`, data, ...args),
  softDeleteMember: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/members/${id}/close`, data, ...args),
  createMemberNote: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/members/${id}/notes/create`, data, ...args),
  updateMemberNote: ({ id, noteId, ...data }, ...args) =>
    post(`/adminapi/v1/members/${id}/notes/${noteId}`, data, ...args),

  getOrganizations: (data, ...args) => get(`/adminapi/v1/organizations`, data, ...args),
  getOrganization: ({ id }) => get(`/adminapi/v1/organizations/${id}`),
  createOrganization: (data, ...args) =>
    post("/adminapi/v1/organizations/create", data, ...args),
  updateOrganization: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/organizations/${id}`, data, ...args),

  getOrganizationMemberships: (data, ...args) =>
    get(`/adminapi/v1/organization_memberships`, data, ...args),
  getOrganizationMembership: ({ id }) =>
    get(`/adminapi/v1/organization_memberships/${id}`),
  createOrganizationMembership: (data, ...args) =>
    post("/adminapi/v1/organization_memberships/create", data, ...args),
  updateOrganizationMembership: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/organization_memberships/${id}`, data, ...args),

  getOrganizationMembershipVerifications: (data, ...args) =>
    get(`/adminapi/v1/organization_membership_verifications`, data, ...args),
  getOrganizationMembershipVerification: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/organization_membership_verifications/${id}`, data, ...args),
  updateOrganizationMembershipVerification: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/organization_membership_verifications/${id}`, data, ...args),
  transitionOrganizationMembershipVerification: ({ id, ...data }, ...args) =>
    post(
      `/adminapi/v1/organization_membership_verifications/${id}/transition`,
      data,
      ...args
    ),
  beginOrganizationMembershipVerificationPartnerOutreach: ({ id, ...data }, ...args) =>
    post(
      `/adminapi/v1/organization_membership_verifications/${id}/begin_partner_outreach`,
      data,
      ...args
    ),
  beginOrganizationMembershipVerificationMemberOutreach: ({ id, ...data }, ...args) =>
    post(
      `/adminapi/v1/organization_membership_verifications/${id}/begin_member_outreach`,
      data,
      ...args
    ),
  addOrganizationMembershipVerificationNote: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/organization_membership_verifications/${id}/notes`, data, ...args),
  editOrganizationMembershipVerificationNote: ({ id, noteId, ...data }) =>
    post(
      `/adminapi/v1/organization_membership_verifications/${id}/notes/${noteId}`,
      data
    ),
  rebuildOrganizationMembershipVerificationDuplicates: ({ id, ...data }, ...args) =>
    post(
      `/adminapi/v1/organization_membership_verifications/${id}/rebuild_duplicates`,
      data,
      ...args
    ),

  getMobilityTrips: (data, ...args) => get(`/adminapi/v1/mobility_trips`, data, ...args),
  getMobilityTrip: ({ id, ...data }, ...args) =>
    get(`/adminapi/v1/mobility_trips/${id}`, data, ...args),
  updateMobilityTrip: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/mobility_trips/${id}`, data, ...args),

  getRoles: (data, ...args) => get(`/adminapi/v1/roles`, data, ...args),
  createRole: (data, ...args) => postForm("/adminapi/v1/roles/create", data, ...args),
  getRole: ({ id, ...data }, ...args) => get(`/adminapi/v1/roles/${id}`, data, ...args),
  updateRole: ({ id, ...data }, ...args) =>
    postForm(`/adminapi/v1/roles/${id}`, data, ...args),

  getStaticStrings: (data, ...args) => get(`/adminapi/v1/static_strings`, data, ...args),
  createStaticString: (data, ...args) =>
    post(`/adminapi/v1/static_strings/create`, data, ...args),
  updateStaticString: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/static_strings/${id}/update`, data, ...args),
  deprecateStaticString: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/static_strings/${id}/deprecate`, data, ...args),
  undeprecatedStaticString: ({ id, ...data }, ...args) =>
    post(`/adminapi/v1/static_strings/${id}/undeprecate`, data, ...args),

  searchProducts: (data, ...args) => post(`/adminapi/v1/search/products`, data, ...args),
  searchOfferings: (data, ...args) =>
    post(`/adminapi/v1/search/offerings`, data, ...args),
  searchPaymentInstruments: (data, ...args) =>
    post(`/adminapi/v1/search/payment_instruments`, data, ...args),
  searchLedgers: (data, ...args) => post(`/adminapi/v1/search/ledgers`, data, ...args),
  searchLedgersLookup: (data, ...args) =>
    post(`/adminapi/v1/search/ledgers/lookup`, data, ...args),
  searchStaticStrings: (data, ...args) =>
    post(`/adminapi/v1/search/static_strings`, data, ...args),
  searchTranslations: (data, ...args) =>
    post(`/adminapi/v1/search/translations`, data, ...args),
  searchVendors: (data, ...args) => post(`/adminapi/v1/search/vendors`, data, ...args),
  searchMembers: (data, ...args) => post(`/adminapi/v1/search/members`, data, ...args),
  searchOrganizations: (data, ...args) =>
    post(`/adminapi/v1/search/organizations`, data, ...args),
  searchRoles: (data, ...args) => post(`/adminapi/v1/search/roles`, data, ...args),
  searchVendorServices: (data, ...args) =>
    post(`/adminapi/v1/search/vendor_services`, data, ...args),
  searchVendorServiceRates: (data, ...args) =>
    post(`/adminapi/v1/search/vendor_service_rates`, data, ...args),
  searchCommerceOffering: (data, ...args) =>
    post(`/adminapi/v1/search/commerce_offerings`, data, ...args),
  searchPrograms: (data, ...args) => post(`/adminapi/v1/search/programs`, data, ...args),

  getFinancialsPlatformStatus: (data, ...args) =>
    get(`/adminapi/v1/financials/platform_status`, data, ...args),

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
