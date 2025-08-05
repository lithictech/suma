import camelCase from "lodash/camelCase";
import kebabCase from "lodash/kebabCase";

const mapping = {
  organizationMembership: "membership",
  organizationMembershipVerification: "membership-verification",
  ledger: "payment-ledger",
};

export function resourceRoute(resource, { plural } = {}) {
  resource = camelCase(resource);
  let p = mapping[resource] || kebabCase(resource);
  if (plural) {
    p = pluralize(p);
  }
  return p;
}

export function resourceListRoute(resource) {
  return `/${resourceRoute(resource, { plural: true })}`;
}

export function resourceCreateRoute(resource) {
  return `/${resourceRoute(resource)}/new`;
}

export function resourceViewRoute(resource, model) {
  return `/${resourceRoute(resource)}/${model.id}`;
}

export function resourceEditRoute(resource, model) {
  return `/${resourceRoute(resource)}/${model.id}/edit?edit=true`;
}

function pluralize(str) {
  // Improve or special case this as needed.
  return str + "s";
}
