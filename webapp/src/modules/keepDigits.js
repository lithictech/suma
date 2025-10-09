/**
 * @param s
 * @returns {string}
 */
export default function (s) {
  return (s || "").replace(/\D/g, "");
}
