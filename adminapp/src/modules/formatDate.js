import dayjs from "dayjs";

/**
 * Run dayjs(value).format('lll').
 *
 * @param value The date string.
 * @param opts
 * @param opts.default The empty date value, defaults to '-'.
 * @param opts.template The template string, defaults to 'lll'.
 * @returns {string}
 */
export default function formatDate(value, opts = {}) {
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
