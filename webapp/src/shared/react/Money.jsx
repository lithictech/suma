import { formatMoney } from "../../shared/money";
import PropTypes from "prop-types";
import React from "react";

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
