/**
 * Safely encode an object as JSON in a url-safe Base64 format.
 */
export function encodeUrlJson(o: any): string {
  const json = JSON.stringify(o);
  const base64 = btoa(json);
  const enc = encodeURIComponent(base64);
  return enc;
}

/**
 * The opposite of encodeUrlJson. Returns the originally encoded object.
 */
export function decodeUrlJson(enc: string): any {
  const base64 = decodeURIComponent(enc);
  const json = atob(base64);
  const o = JSON.parse(json);
  return o;
}
