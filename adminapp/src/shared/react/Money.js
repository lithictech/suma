import { Logger } from "../logger";
import get from "lodash/get";
import merge from "lodash/merge";
import PropTypes from "prop-types";
import React from "react";

const logger = new Logger("money");

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

export default function Money({ value, children, className, accounting, as, ...rest }) {
  let entity = value || children;
  if (!entity) {
    return null;
  }
  let ch;
  if (accounting && entity.cents < 0) {
    ch = `(${formatMoney({ ...entity, cents: Math.abs(entity.cents) }, rest)})`;
  } else {
    ch = formatMoney(entity, rest);
  }
  const As = as || "span";
  return <As className={className}>{ch}</As>;
}

Money.propTypes = {
  value: PropTypes.shape({
    cents: PropTypes.number,
    currency: PropTypes.string,
  }),
  children: PropTypes.any,
  className: PropTypes.string,
  rounded: PropTypes.bool,
};

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

export function floatToMoney(f, currency) {
  return {
    cents: f * 100,
    currency,
  };
}

export function intToMoney(cents, currency) {
  return {
    cents: cents,
    currency,
  };
}

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

export function addMoney(m1, m2) {
  return mathMoney(m1, m2, (x, y) => x + y);
}

export function subtractMoney(m1, m2) {
  return mathMoney(m1, m2, (x, y) => x - y);
}

export function scaleMoney(m, n) {
  return {
    cents: m.cents * n,
    currency: m.currency,
  };
}

export function anyMoney(m) {
  if (!m) {
    return false;
  }
  const cents = m.cents;
  return cents > 0 || cents < 0;
}
