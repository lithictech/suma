import toUrl from "./toUrl";
import _ from "lodash";

/**
 * Set part of a full URL.
 * @param {string=} hash
 * @param {string=} search
 * @param {object=} setParams Set these query params. Use null or undefined to remove a param.
 * @param {object=} replaceParams Replace all query params with this set. Null or undefined are not added to the URL.
 * @param {LocationLike=} location
 * @returns {string}
 */
export default function setUrlPart({ hash, search, setParams, replaceParams, location }) {
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

function updateParams(sp, pairs) {
  _.forEach(pairs, (v, k) => {
    if (v === null || v === undefined) {
      sp.delete(k);
    } else {
      sp.set(k, v);
    }
  });
}
