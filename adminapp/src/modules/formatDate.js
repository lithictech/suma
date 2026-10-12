import dayjs from "dayjs";

/**
 * Run dayjs(value).format('lll').
 *
 * @param value The date string. If undefined, warn. If null/falsey, will default to today.
 *   Warning finds field typos (which should be caught via typescript in the future).
 * @param {object=} opts
 * @param {string=} opts.default The empty date value, defaults to '-'.
 * @param {string=} opts.template The template string, defaults to 'lll'.
 * @returns {string}
 */
export default function formatDate(value, opts = {}) {
  if (value === undefined) {
    console.warn("passed undefined to formatDate, use null if intended");
    return "UNDEFINED";
  }
  let d = opts.default;
  if (d === undefined) {
    d = "-";
  }
  const t = dayjs(value);
  if (!t.isValid()) {
    return d;
  }
  let tmpl = opts.template;
  if (tmpl === undefined) {
    tmpl = "lll";
  }
  return t.format(tmpl);
}
