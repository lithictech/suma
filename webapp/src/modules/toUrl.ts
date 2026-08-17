import has from "lodash/has";

export type LocationLike =
  | string
  | URL
  | { href: string }
  | { pathname: string; search: string; hash: string };

export default function toUrl(x: LocationLike): URL {
  if (typeof x === "string") {
    return new URL(x);
  } else if (x instanceof URL) {
    return new URL(x.href);
  } else if (has(x, "href")) {
    return new URL((x as { href: string }).href);
  } else if (has(x, "pathname")) {
    // Usually this a react-router location thingy
    const loc = x as { pathname: string; search: string; hash: string };
    const u = new URL(window.location.href);
    u.pathname = loc.pathname;
    u.search = loc.search;
    u.hash = loc.hash;
    return u;
  } else {
    throw new Error(`${JSON.stringify(x)} cannot be converted to a URL`);
  }
}
