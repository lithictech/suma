import dayjs from "dayjs";

/**
 * @param val {string,dayjs}
 * @param template {string}
 * @param default_ {string=}
 */
export default function dateFormat(val, template, default_) {
  if (!val) {
    return default_ || "";
  }
  const d = dayjs(val);
  if (!d.isValid()) {
    return default_ || "";
  }
  return d.format(template);
}
