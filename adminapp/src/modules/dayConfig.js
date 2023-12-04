// This module allows extension of plugins with dayjs globally,
// preventing the redundancy of extending any plugin in different
// pages, uncomment any plugin you wish to extend/utilize
import dayjs from "dayjs";
import "dayjs/locale/en";
import localizedFormat from "dayjs/plugin/localizedFormat";
import timezone from "dayjs/plugin/timezone";
import utc from "dayjs/plugin/utc";

dayjs.extend(timezone);
dayjs.extend(utc);
dayjs.extend(localizedFormat);

dayjs.locale("en");

function dayjsOrNull(arg) {
  return arg === null ? null : dayjs(arg);
}

function formatOrNull(arg) {
  return arg === null ? null : arg.format();
}

export { dayjs, dayjsOrNull, formatOrNull };
