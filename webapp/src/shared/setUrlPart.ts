import toUrl, { LocationLike } from "./toUrl";
import forEach from "lodash/forEach";

interface SetUrlPartArgs {
  hash?: string;
  search?: string;
  /** Set these query params. Use null or undefined to remove a param. */
  setParams?: Record<string, string | null | undefined>;
  /** Replace all query params with this set. Null or undefined are not added to the URL. */
  replaceParams?: Record<string, string | null | undefined>;
  location?: LocationLike;
}

/**
 * Set part of a full URL.
 */
export default function setUrlPart({
  hash,
  search,
  setParams,
  replaceParams,
  location,
}: SetUrlPartArgs): string {
  const url = toUrl(location || window.location.href);
  if (hash !== undefined) {
    url.hash = hash;
  }
  if (search !== undefined) {
    url.search = search;
  }
  if (replaceParams !== undefined) {
    const sp = new URLSearchParams();
    updateParams(sp, replaceParams);
    url.search = sp.toString();
  }
  if (setParams !== undefined) {
    const sp = url.searchParams;
    updateParams(sp, setParams);
    url.search = sp.toString();
  }
  return url.toString();
}

function updateParams(
  sp: URLSearchParams,
  pairs: Record<string, string | null | undefined>
) {
  forEach(pairs, (v, k) => {
    if (v === null || v === undefined) {
      sp.delete(k);
    } else {
      sp.set(k, v);
    }
  });
}
