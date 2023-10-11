import has from "lodash/has";

/**
 * @param {LocationLike} x
 */
export default function toUrl(x) {
  if (typeof x === "string") {
    return new URL(x);
  } else if (x instanceof URL) {
    return new URL(x.href);
  } else if (has(x, "href")) {
    return new URL(x.href);
  } else if (has(x, "pathname")) {
    // Usually this a react-router location thingy
    const u = new URL(window.location.href);
    u.pathname = x.pathname;
    u.search = x.search;
    u.hash = x.hash;
    return u;
  } else {
    throw new Error(`${JSON.stringify(x)} cannot be converted to a URL`);
  }
}

/**
 * @typedef {string|Location|URL} LocationLike
 */
