import { Logger } from "./logger";
import isEmpty from "lodash/isEmpty";
import merge from "lodash/merge";

const logger = new Logger("money");

export interface FormatMoneyOptions {
  /**
   * If true, use smart rounding. 0 cents will use no extra digits (ie, $1) and
   * nonzero cents will have 2 extra digits (ie, $1.05). Ie, you'll never get $1.00.
   */
  rounded?: boolean;
  /** If given, strip off the leading currency symbol. */
  noCurrency?: boolean;
}

export const formatMoney = (entity: Money, options?: FormatMoneyOptions): string => {
  const formatterOpts: Intl.NumberFormatOptions = {};
  options = options || {};
  if (options.rounded) {
    const hasCents = entity.cents % 100 > 0;
    formatterOpts.minimumFractionDigits = hasCents ? 2 : 0;
  }

  let formatter;
  if (isEmpty(formatterOpts)) {
    formatter = defaultFormatters[entity.currency] || defaultFormatters.default;
  } else {
    const ctor = optionedFormatters[entity.currency] || optionedFormatters.default;
    formatter = ctor(formatterOpts);
  }
  let r = formatter.format(entity.cents / 100.0);
  if (options.noCurrency) {
    // No way to do this with Intl as far as I can tell, so strip non-number/placement chars.
    r = r.replace(/[^\d.,\- \s]+/g, "").trim();
  }
  return r;
};

/**
 * Return a Money with the given fraction, which represents dollars
 * (ie, 1.5 is $1.50).
 */
export function floatToMoney(f: number, currency: string): Money {
  return {
    cents: f * 100,
    currency,
  };
}

/**
 * Return a Money with the given cents and currency.
 */
export function intToMoney(cents: number, currency: string): Money {
  return {
    cents,
    currency,
  };
}

/**
 * Apply a two-operand mathematical function to the two monies.
 * Money entities must have the same currency.
 */
export function mathMoney(
  m1: Money,
  m2: Money,
  t: (a: number, b: number) => number
): Money {
  // noinspection JSUnresolvedVariable
  if (window.__DEV__) {
    if (m1.currency !== m2.currency) {
      logger.context({ money1: m1, money2: m2 }).error("money_currency_mismatch");
    }
  }
  return {
    cents: t(m1.cents, m2.cents),
    currency: m2.currency,
  };
}

export function addMoney(m1: Money, m2: Money): Money {
  return mathMoney(m1, m2, (x, y) => x + y);
}

export function subtractMoney(m1: Money, m2: Money): Money {
  return mathMoney(m1, m2, (x, y) => x - y);
}

/**
 * Multiply the number of cents by the given factor.
 */
export function scaleMoney(m: Money, n: number): Money {
  return {
    cents: m.cents * n,
    currency: m.currency,
  };
}

/**
 * Return true if m is present and its cents are non-zero.
 */
export function anyMoney(m: Money): boolean {
  return moneySign(m) !== 0;
}

/**
 * Return -1 if money is negative, 0 if zero or falsey, 1 if positive.
 */
export function moneySign(m: Money): number {
  if (!m) {
    return 0;
  }
  const cents = m.cents;
  if (cents === 0) {
    return 0;
  } else if (cents > 0) {
    return 1;
  }
  return -1;
}

const optionedFormatters: Record<
  string,
  (opts: Intl.NumberFormatOptions) => Intl.NumberFormat
> & {
  default?: (opts: Intl.NumberFormatOptions) => Intl.NumberFormat;
} = {
  USD: (opts) =>
    new Intl.NumberFormat(
      "en-US",
      merge(
        {
          style: "currency",
          currency: "USD",
        },
        opts
      )
    ),
};
optionedFormatters.default = optionedFormatters.USD;

const defaultFormatters: Record<string, Intl.NumberFormat> & {
  default?: Intl.NumberFormat;
} = {
  USD: optionedFormatters.USD({}),
};
defaultFormatters.default = defaultFormatters.USD;
