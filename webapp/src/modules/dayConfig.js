// This module allows extension of plugins with dayjs globally,
// preventing the redundancy of extending any plugin in different
// pages, uncomment any plugin you wish to extend/utilize
import { getCurrentLanguage } from "../localization/useI18Next";
import dayjs from "dayjs";
// import advancedFormat from 'dayjs/plugin/advancedFormat';
// import customParseFormat from 'dayjs/plugin/customParseFormat';
// import isBetween from 'dayjs/plugin/isBetween';
// import isYesterday from 'dayjs/plugin/isYesterday';
// import isToday from 'dayjs/plugin/isToday';
// import isTomorrow from 'dayjs/plugin/isTomorrow';
// import relativeTime from 'dayjs/plugin/relativeTime';
import "dayjs/locale/en";
import "dayjs/locale/es";
// import utc from 'dayjs/plugin/utc';
import localizedFormat from "dayjs/plugin/localizedFormat";
import timezone from "dayjs/plugin/timezone";
import i18n from "i18next";

dayjs.extend(timezone);
// dayjs.extend(utc);
dayjs.extend(localizedFormat);
// dayjs.extend(advancedFormat);
// dayjs.extend(customParseFormat);
// dayjs.extend(isBetween);
// dayjs.extend(isYesterday);
// dayjs.extend(isToday);
// dayjs.extend(isTomorrow);
// dayjs.extend(relativeTime);

dayjs.locale(getCurrentLanguage() || "en");
export {
  dayjs,
  // utc,
  // timezone,
  // localizedFormat,
  // advancedFormat,
  // customParseFormat,
  // isBetween,
  // isYesterday,
  // isToday,
  // isTomorrow,
  // relativeTime
};
