/**
 * Safely encode an object as JSON in a url-safe Base64 format.
 * @param o
 */
export function encodeUrlJson(o) {
  const json = JSON.stringify(o);
  const base64 = btoa(json);
  const enc = encodeURIComponent(base64);
  return enc;
}

/**
 * The opposite of encodeUrlJson. Returns the originally encoded object.
 */
export function decodeUrlJson(enc) {
  const base64 = decodeURIComponent(enc);
  const json = atob(base64);
  const o = JSON.parse(json);
  return o;
}
