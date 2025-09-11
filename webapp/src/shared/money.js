import { Logger } from "./logger";
import get from "lodash/get";
import merge from "lodash/merge";

const logger = new Logger("money");

/**
 * @typedef MoneyEntity
 * @property {number} cents
 * @property {string} currency
 */

/**
 * @param {MoneyEntity} entity
 * @param {object=} options
 * @param {boolean=} options.rounded If true, use smart rounding.
 *   0 cents will use no extra digits (ie, $1) and nonzero cents
 *   will have 2 extra digits (ie, $1.05). Ie, you'll never get $1.00.
 * @returns {string}
 */
export const formatMoney = (entity, options) => {
  let formatterOpts = null;
  if (get(options, "rounded")) {
    const hasCents = entity.cents % 100 > 0;
    formatterOpts = { minimumFractionDigits: hasCents ? 2 : 0 };
  }

  let formatter;
  if (!formatterOpts) {
    formatter = defaultFormatters[entity.currency] || defaultFormatters.default;
  } else {
    const ctor = optionedFormatters[entity.currency] || optionedFormatters.default;
    formatter = ctor(formatterOpts);
  }
  return formatter.format(entity.cents / 100.0);
};

/**
 * Return a MoneyEntity with the given fraction, which represents dollars
 * (ie, 1.5 is $1.50).
 * @param {number} f
 * @param {string} currency
 * @returns {MoneyEntity}
 */
export function floatToMoney(f, currency) {
  return {
    cents: f * 100,
    currency,
  };
}

/**
 * Return a MoneyEntity with the given cents and currency.
 * @param {number} cents
 * @param {string} currency
 * @returns {MoneyEntity}
 */
export function intToMoney(cents, currency) {
  return {
    cents,
    currency,
  };
}

/**
 * Apply a two-operand mathematical function to the two monies.
 * Money entities must have the same currency.
 * @param {MoneyEntity} m1
 * @param {MoneyEntity} m2
 * @param {function} t
 * @returns {MoneyEntity}
 */
export function mathMoney(m1, m2, t) {
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

/**
 * @param {MoneyEntity} m1
 * @param {MoneyEntity} m2
 * @returns {MoneyEntity}
 */
export function addMoney(m1, m2) {
  return mathMoney(m1, m2, (x, y) => x + y);
}

/**
 * @param {MoneyEntity} m1
 * @param {MoneyEntity} m2
 * @returns {MoneyEntity}
 */
export function subtractMoney(m1, m2) {
  return mathMoney(m1, m2, (x, y) => x - y);
}

/**
 * Multiply the number of cents by the given factor.
 * @param {MoneyEntity} m
 * @param {number} n
 * @returns {MoneyEntity}
 */
export function scaleMoney(m, n) {
  return {
    cents: m.cents * n,
    currency: m.currency,
  };
}

/**
 * Return true if m is present and its cents are non-zero.
 * @param {MoneyEntity} m
 * @returns {boolean}
 */
export function anyMoney(m) {
  return moneySign(m) !== 0;
}

/**
 * Return -1 if money is negative, 0 if zero or falsey, 1 if positive.
 * @param m
 * @return {number}
 */
export function moneySign(m) {
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

const optionedFormatters = {
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

const defaultFormatters = {
  USD: optionedFormatters.USD(),
};
defaultFormatters.default = defaultFormatters.USD;
