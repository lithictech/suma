import cct from "credit-card-type";
import { CreditCardType } from "credit-card-type/dist/types";
import luhn from "luhn";

export interface PaymentCardParams {
  name: string;
  number: string;
  expiry: string;
  cvc: string;
}
export type PaymentCardField = keyof PaymentCardParams;

export class PaymentCardInfo {
  name: string;
  number: string;
  expiry: string;
  cvc: string;
  ccts: CreditCardType[];
  cct: CreditCardType | null;

  constructor({ name, number, expiry, cvc }: Partial<PaymentCardParams>) {
    this.name = name || "";
    this.number = keepDigits(number || "");
    this.expiry = keepDigits(expiry || "");
    this.cvc = keepDigits(cvc || "");
    this.ccts = cct(this.number);
    this.cct = null;
    if (this.ccts.length === 1) {
      this.cct = this.ccts[0];
    }
  }

  change(fields: Partial<PaymentCardParams>) {
    const args: PaymentCardParams = {
      name: this.name,
      number: this.number,
      expiry: this.expiry,
      cvc: this.cvc,
      ...fields,
    };
    return new PaymentCardInfo({ ...args });
  }
}

const Invalid = {
  EXPIRED: "expired",
  FORMAT: "format",
};

/**
 * Given a function like invalidCardNumberReason,
 * return a function that takes a string, creates a PaymentCardInfo
 * using the seed and the given string,
 * and returns true if valid and false if not.
 */
function validator(
  field: PaymentCardField,
  reasonFunc: (ci: PaymentCardInfo) => string,
  seed?: Partial<PaymentCardParams>
): (s: string) => boolean {
  return (s) => {
    const arg = { ...seed, [field]: s };
    const pci = new PaymentCardInfo(arg);
    return !reasonFunc(pci);
  };
}

/**
 * Return the reason a card number is invalid,
 * or empty string if valid.
 */
function invalidCardNumberReason(ci: PaymentCardInfo): string {
  const number = keepDigits(ci.number);
  console.log(number, luhn.validate(number));
  if (!luhn.validate(number) || !ci.cct) {
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
 */
function invalidCardExpiryReason(ci: PaymentCardInfo, today: Date = new Date()): string {
  const exp = parseExpiry(ci.expiry);
  if (!exp || !exp.year || !exp.full) {
    return Invalid.FORMAT;
  }
  if (exp.year < today.getFullYear()) {
    return Invalid.EXPIRED;
  } else if (exp.year === today.getFullYear() && exp.month < today.getMonth()) {
    return Invalid.EXPIRED;
  }
  return "";
}

interface ParsedExpiry {
  month: number;
  year: number | null;
  full: boolean;
}

function parseExpiry(s: string | null): ParsedExpiry | null {
  const digits = keepDigits(s);
  if (digits.length <= 1) {
    return null;
  }
  let month: number;
  let year: number | null = null;
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
 */
function invalidCardCvcReason(ci: PaymentCardInfo): string {
  const cvc = keepDigits(ci.cvc);
  if (!ci.cct || cvc.length !== ci.cct.code.size) {
    return Invalid.FORMAT;
  }
  return "";
}

interface FormatOptions {
  /**
   * If true, use this as a placeholder for missing values.
   * format(number='4242', placeholder='x') would result in '4242 xxxx xxxx xxxx'.
   */
  placeholder?: string;
  /**
   * If true, if the length of the value is equal to a number gap, add a space.
   * So '4242 4' would become '4242 ' so the user's next input would start a new
   * space-separated string.
   */
  editing?: boolean;
}

/**
 * Format the card info number, using the placeholder to pad it out if needed.
 */
function formatCardNumber(ci: PaymentCardInfo, options?: FormatOptions): string {
  const cct = ci.cct || DEFAULT_CCT;
  const s = keepDigits(ci.number).substring(0, Math.max(...cct.lengths));
  const parts: string[] = [];
  let lastIdx = 0;
  [...cct.gaps, Math.max(Math.min(...cct.lengths), s.length)].forEach((gapIdx) => {
    let part = s.substring(lastIdx, gapIdx);
    if (options?.placeholder) {
      part = part.padEnd(gapIdx - lastIdx, options.placeholder);
    }
    parts.push(part);
    lastIdx = gapIdx;
  });
  let result = parts.filter(Boolean).join(" ");
  if (options?.editing && cct.gaps.includes(s.length)) {
    result += " ";
  }
  return result;
}

interface FormatExpiryOptions extends FormatOptions {
  /**
   * By default, this function will format the expiry only using the input string-
   * that is, '120' is '12/0'. If infer is true, the format will be inferred as per
   * parseExpiry, and this method would return '01/20'. This is mostly useful when an
   * input loses focus and we want to try to create a fully valid expiry using partial entry.
   */
  infer?: boolean;
}

/**
 * Format the card info expiry, using the placeholder to pad it out if needed.
 */
function formatCardExpiry(ci: PaymentCardInfo, options?: FormatExpiryOptions): string {
  let mpart: string, ypart: string;
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
  if (options?.editing) {
    if (mpart.length < 2) {
      return mpart;
    }
  }
  return `${mpart} / ${ypart}`;
}

/**
 * Format the card info cvc, using the placeholder to pad it out if needed.
 * options.editing is currently unused.
 */
function formatCardCvc(ci: PaymentCardInfo, options?: FormatOptions): string {
  const cct = ci.cct || DEFAULT_CCT;
  const maxCodeLen = cct.code.size;
  let s = keepDigits(ci.cvc).substring(0, maxCodeLen);
  if (options?.placeholder) {
    s = s.padEnd(maxCodeLen, options.placeholder);
  }
  return s;
}

const DEFAULT_CCT = cct.getTypeInfo("visa");

interface DigitInputEvent {
  target: { name?: string; value: string };
  inputType?: string;
}

interface DigitInputOptions {
  /** The card info being changed. */
  pci: PaymentCardInfo;
  /** The name of the field being changed. Default to ev.target.name. */
  field: PaymentCardField;
}

/**
 * Use this when changing card number, expiry, and cvc inputs.
 * This is necessary because the inputs have formatting automatically applied
 * to the input value; but if the user backspaces, they delete the formatting,
 * not the digit.
 *
 * This method will:
 * - Preserve only digits.
 * - If some text is being deleted (backspace), remove the last digit.
 */
function handleDigitInputWithFormatting(
  ev: DigitInputEvent,
  options: DigitInputOptions
): string {
  const formatter = FORMATTERS[options.field];
  const previousFormattedValue = formatter(options.pci, { editing: true });
  const d = keepDigits(ev.target.value);
  if (
    ev.inputType === "deleteContentBackward" &&
    !isDigit(last(previousFormattedValue))
  ) {
    return d.substring(0, d.length - 1);
  }
  return d;
}

const FORMATTERS: Record<
  PaymentCardField,
  (ci: PaymentCardInfo, options?: FormatOptions) => string
> = {
  name: () => "",
  number: formatCardNumber,
  expiry: formatCardExpiry,
  cvc: formatCardCvc,
};

const last = (x: string) => x[x.length - 1];
const keepDigits = (s: string | null) => (s || "").replace(/\D/g, "");
const isDigit = (s: string) => (s || "").match(/\d/);

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
  FORMATTERS,
  handleDigitInputWithFormatting,
};

export default Payment;
