/**
 * Return [relative href, true] or
 * [href, false], depending on the following:
 *
 * - If href is relative, return it as relative verbatim: [href, true].
 * - If href starts with the current protocol/host and the app public url,
 *   return it as a real relative url to the application.
 *   For example, at `http://x.y/myapp` (that is, a BASE_URL of 'myapp')
 *   using href `http://xy.y/myapp/page1`, return `/page1`.
 *   At `http://x.y` (that is, a BASE_URL of '')
 *   using href `http://xy.y/myapp/page1`, return `/myapp/page1`.
 * - Otherwise, return [href, false]. That is, at `http://x.y/myapp`,
 *   the hrefs `http://a.b/myapp/page` and `http://x.y/page1`
 *   would both be treated as non-relative.
 *
 * @param {string} href
 * @returns {[string,boolean]}
 */
export default function relativeLink(href) {
  if (href.startsWith(start)) {
    return [href.slice(start.length - 1), true];
  } else {
    return [href, false];
  }
}

// BASE_URL must have trailing slash
const baseUrl = import.meta.env.BASE_URL.replace(/\/$/, "") + "/";

const start = `${window.location.protocol}//${window.location.host}${baseUrl}`;
