/**
 * @param {string} str
 * @returns {string}
 */
export default function pluralize(str) {
  if (!str || str.length <= 1) {
    return str;
  }
  if (str[str.length - 1] === "y") {
    return str.slice(0, str.length - 1) + "ies";
  }
  return str + "s";
}
