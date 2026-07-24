import dayjs from "dayjs";

/**
 * Run dayjs(value).format('lll').
 *
 * @param value The date string.
 * @param {object=} opts
 * @param {string=} opts.default The empty date value, defaults to '-'.
 * @param {string=} opts.template The template string, defaults to 'lll'.
 * @param {boolean=} opts.looseEmpty
 * @returns {string}
 */
export default function formatDate(value, opts = {}) {
  let d = opts.default;
  if (d === undefined) {
    d = "-";
  }
  if (!value && opts.looseEmpty) {
    return d;
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
