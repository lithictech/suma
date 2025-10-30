import { formatMoney } from "../money";
import clsx from "clsx";
import React from "react";

/**
 * @param {MoneyEntity} value
 * @param children
 * @param {string=} className
 * @param {boolean} accounting
 * @param as
 * @param rest
 */
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
  return <As className={clsx("text-nowrap", className)}>{ch}</As>;
}
