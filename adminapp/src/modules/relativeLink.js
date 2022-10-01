/**
 * Parse the given href as a relative link,
 * if it has the same root as the current URL.
 * Return the relative link and true if the given href is relative,
 * or the given href and false if not relative.
 *
 * @param {string} href
 * @returns {[string,boolean]}
 */
export default function relativeLink(href) {
  if (href.startsWith(start)) {
    return [href.slice(start.length), true];
  } else {
    return [href, false];
  }
}

const start = `${window.location.protocol}//${window.location.host}`;
