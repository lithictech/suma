/**
 * Based on https://github.com/openexchangerates/accounting.js/blob/master/accounting.js
 * @param {string|number} value
 * @param {string=} decimal
 * @returns {number}
 */
export default function parseCurrency(value, decimal) {
  value = value || 0;
  // Return the value as-is if it's already a number:
  if (typeof value === "number") {
    return value;
  }

  value = "" + value;

  // Default decimal point comes from settings, but could be set to eg. "," in opts:
  decimal = decimal || findDecimal(value);

  // Build regex to strip out everything except digits, decimal point and minus sign:
  const regex = new RegExp("[^0-9-" + decimal + "]", ["g"]);
  const unformatted = parseFloat(
    value
      .replace(/\((?=\d+)(.*)\)/, "-$1") // replace bracketed values with negatives
      .replace(regex, "") // strip out any cruft
      .replace(decimal, ".") // make sure decimal point is standard
  );

  // This will fail silently which may cause trouble, let's wait and see:
  return !isNaN(unformatted) ? unformatted : 0;
}

function findDecimal(s) {
  const p = new Intl.NumberFormat()
    .formatToParts(s)
    .find(({ type }) => type === "decimal");
  return p ? p.value : ".";
}
