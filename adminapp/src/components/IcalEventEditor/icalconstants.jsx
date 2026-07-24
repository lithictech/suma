import { dayjs } from "../../modules/dayConfig";
import isArray from "lodash/isArray";
import isNumber from "lodash/isNumber";

export const bydays = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"];
export const bydaysLabels = {
  MO: "MON",
  TU: "TUE",
  WE: "WED",
  TH: "THU",
  FR: "FRI",
  SA: "SAT",
  SU: "SUN",
};

export const frequencies = ["DAILY", "WEEKLY", "MONTHLY"];
export const frequencyLabels = {
  DAILY: "days",
  WEEKLY: "weeks",
  MONTHLY: "months",
};

export const endModes = ["after", "on"];

/**
 * @param {dayjs.Dayjs} d
 * @returns {string}
 */
export function icalDate(d) {
  return d.format("YYYYMMDDHHmmss[Z]");
}

/**
 * @typedef IcalRruleState
 * @property {string} FREQ
 * @property {number} INTERVAL
 * @property {number} COUNT
 * @property {dayjs.Dayjs} UNTIL
 * @property {string[]} BYDAY
 * @property {number[]} BYMONTHDAY
 * @property {number[]} BYSETPOS
 */

/**
 * @params {object=} options
 * @returns {IcalRruleState}
 */
export function icalRruleState() {
  return {
    FREQ: "",
    INTERVAL: 0,
    COUNT: 0,
    UNTIL: null,
    BYDAY: [],
    BYMONTHDAY: [],
    BYSETPOS: [],
  };
}

export function renderRruleState(state) {
  const parts = [];
  Object.entries(state).forEach(([k, v]) => {
    let s = "";
    if (isArray(v)) {
      s = v.join(",");
    } else if (dayjs.isDayjs(v)) {
      s = icalDate(v);
    } else if (v) {
      s = "" + v;
    }
    if (s) {
      parts.push(`${k}=${s}`);
    }
  });
  return parts.join(";");
}

/**
 * @param {string} s
 * @param {object=} options
 * @param {boolean=} options.reset
 * @return {object}
 */
export function parseIcalRrule(s, options) {
  const reset = (options || {}).reset;
  const result = reset ? icalRruleState() : {};

  const parts = s.split(";");
  parts.forEach((part) => {
    let [k, v] = part.split("=");
    if (!k || !v) {
      return;
    }
    const defaultV = defaultRruleState[k];
    if (isArray(defaultV)) {
      v = v.split(",");
    } else if (isNumber(defaultV)) {
      v = Number(v);
    } else if (dayjs.isDayjs(defaultV)) {
      v = dayjs(v);
    }
    result[k] = v;
  });
  return result;
}

const defaultRruleState = icalRruleState();
