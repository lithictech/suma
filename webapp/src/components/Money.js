import _ from "lodash";
import PropTypes from "prop-types";
import React from "react";

const optionedFormatters = {
  USD: (opts) =>
    new Intl.NumberFormat(
      "en-US",
      _.merge(
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

export default function Money({ value, children, className, accounting, ...rest }) {
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
  return <span className={className}>{ch}</span>;
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
  if (_.get(options, "rounded")) {
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
      console.error("moneys must have the same currency:", m1, m2);
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
