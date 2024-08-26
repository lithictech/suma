import camelCase from "lodash/camelCase";
import kebabCase from "lodash/kebabCase";

const mapping = {
  eligibilityConstraint: "constraint",
  organizationMembership: "membership",
};

export function resourceRoute(resource) {
  resource = camelCase(resource);
  if (mapping[resource]) {
    return mapping[resource];
  }
  return kebabCase(resource);
}

export function resourceListRoute(resource) {
  return `/${resourceRoute(resource)}`;
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
