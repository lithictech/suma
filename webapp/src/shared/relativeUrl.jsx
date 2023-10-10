import toUrl from "./toUrl";

/**
 * @param {LocationLike} location
 * @returns {string}
 */
export default function relativeUrl({ location }) {
  const url = toUrl(location);
  const schemIdx = url.href.indexOf("://");
  const hostLen = url.host.length;
  return url.href.slice(schemIdx + hostLen + 3); // 3 is length of ://
}
