import keepDigits from "./keepDigits.js";
import cct from "credit-card-type";
import luhn from "luhn";

export class PaymentCardInfo {
  constructor(number, expiry, cvc) {
    this.number = number;
    this.expiry = expiry;
    this.cvc = cvc;
    this.ccts = cct(this.number);
    this.cct = this.ccts[0];
  }
}

const Invalid = {
  EXPIRED: "expired",
  FORMAT: "format",
};

/**
 * Given a function like invalidCardNumberReason,
 * return a function that returns true if valid and false if not.
 * @param {function(PaymentCardInfo): string} f
 * @return {function(string): boolean}
 */
function validator(f) {
  return (s) => !f(s);
}

/**
 * Return the reason a card number is invalid,
 * or empty string if valid.
 * @param {PaymentCardInfo} ci
 * @returns {string}
 */
function invalidCardNumberReason(ci) {
  const number = keepDigits(ci.number);
  if (!luhn.validate(number)) {
    return Invalid.FORMAT;
  }
  if (!ci.cct.lengths.includes(number.length)) {
    return Invalid.FORMAT;
  }
  return "";
}

/**
 * Return the reason a card expiry is invalid,
 * or empty string if valid.
 * @param {PaymentCardInfo} ci
 * @param {Date} today
 * @returns {string}
 */
function invalidCardExpiryReason(ci, today = new Date()) {
  const exp = parseExpiry(ci.expiry);
  if (!exp?.year) {
    return Invalid.FORMAT;
  }
  if (exp.year < today.getFullYear()) {
    return Invalid.EXPIRED;
  } else if (exp.year === today.getFullYear() && exp.month < today.getMonth()) {
    return Invalid.EXPIRED;
  }
  return "";
}

/**
 * @param {string} s
 * @returns {{month: number, year: number|null, full: boolean}|null}
 */
function parseExpiry(s) {
  const digits = keepDigits(s);
  if (digits.length <= 1) {
    return null;
  }
  let month;
  let year = null;
  let full = false;
  switch (digits.length) {
    case 2:
      month = parseInt(digits, 10);
      return month >= 1 && month <= 12 ? { month, year, full } : null;
    case 3:
      // heuristic: first digit = month (0x or x)
      month = parseInt(digits.slice(0, 1), 10);
      year = parseInt(digits.slice(1), 10);
      if (month < 1 || month > 12) {
        // maybe first two digits are month
        month = parseInt(digits.slice(0, 2), 10);
        year = parseInt(digits.slice(2), 10);
      }
      break;
    default:
      month = parseInt(digits.slice(0, 2), 10);
      year = parseInt(digits.slice(2, 4), 10);
      full = true;
  }
  if (month < 1 || month > 12) {
    return null;
  }
  if (year < 100) {
    // Normalize 2 digit year to 20xx.
    year += 2000;
  }
  return { month, year, full };
}

/**
 * Return the reason a card CVC is invalid,
 * or empty string if valid.
 * @param {PaymentCardInfo} ci
 * @returns {string}
 */
function invalidCardCvcReason(ci) {
  const cvc = keepDigits(ci.cvc);
  if (cvc.length !== ci.cct.code.size) {
    return Invalid.FORMAT;
  }
  return "";
}

/**
 * Format the card info number, using the placeholder to pad it out if needed.
 * @param {PaymentCardInfo} ci
 * @param {object=} options
 * @param {string=} options.placeholder
 * @returns {string}
 */
function formatCardNumber(ci, options) {
  const s = keepDigits(ci.number);
  const parts = [];
  let lastIdx = 0;
  [...ci.cct.gaps, Math.max(Math.min(...ci.cct.lengths), s.length)].forEach((gapIdx) => {
    let part = s.substring(lastIdx, gapIdx);
    if (options?.placeholder) {
      part = part.padEnd(gapIdx - lastIdx, options.placeholder);
    }
    parts.push(part);
    lastIdx = gapIdx;
  });
  // console.log(ci.cct);
  return parts.filter(Boolean).join(" ");
}

/**
 * Format the card info expiry, using the placeholder to pad it out if needed.
 * @param {PaymentCardInfo} ci
 * @param {object=} options
 * @param {string=} options.placeholder
 * @param {boolean=} options.infer By default, this function will format the expiry
 *   only using the input string- that is, '120' is '12/0'.
 *   If infer is true, the format will be inferred as per parseExpiry,
 *   and this method would return '01/20'.
 *   This is mostly useful when an input loses focus and we want to try
 *   to create a fully valid expiry using partial entry.
 * @returns {string}
 */
function formatCardExpiry(ci, options) {
  let mpart, ypart;
  if (options?.infer) {
    const parseResult = parseExpiry(ci.expiry);
    if (!parseResult) {
      mpart = "";
      ypart = "";
    } else {
      const { year, month } = parseResult;
      mpart = (month + "").substring(0, 2).padStart(2, "0");
      ypart = year ? (year + "").substring(2, 4) : "";
    }
  } else {
    const s = keepDigits(ci.expiry);
    mpart = s.substring(0, 2);
    ypart = s.substring(2, 4);
  }
  if (options?.placeholder) {
    mpart = mpart.padEnd(2, options.placeholder);
    ypart = ypart.padEnd(2, options.placeholder);
  }
  return `${mpart} / ${ypart}`;
  //
  // const { month, year, full } = parseExpiry(ci.expiry);
  // // Get month year as 01, 12, etc.
  // const m = (month + "").padStart(2, "0");
  // // Year string is more complex.
  // const y = year ? (year + "").substring(2) : "";
  // return `${m} / ${y}`;
}

/**
 * Format the card info cvc, using the placeholder to pad it out if needed.
 * @param {PaymentCardInfo} ci
 * @param {object=} options
 * @param {string=} options.placeholder
 * @returns {string}
 */
function formatCardCvc(ci, options) {
  let s = keepDigits(ci.cvc);
  if (options?.placeholder) {
    s = s.padEnd(ci.cct?.code.size || 3, options.placeholder);
  }
  return s;
}

const Payment = {
  CardInfo: PaymentCardInfo,
  Invalid,
  invalidCardNumberReason,
  invalidCardExpiryReason,
  invalidCardCvcReason,
  validator,
  parseExpiry,
  formatCardNumber,
  formatCardExpiry,
  formatCardCvc,
};

export default Payment;
