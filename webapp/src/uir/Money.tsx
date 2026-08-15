import { formatMoney, FormatMoneyOptions } from "../shared/money";
import clsx from "clsx";
import React from "react";

interface MoneyProps extends FormatMoneyOptions {
  value?: Money;
  children?: Money;
  className?: string;
  accounting?: boolean;
  as?: React.ElementType;
}

export default function Money({
  value,
  children,
  className,
  accounting,
  as,
  ...rest
}: MoneyProps) {
  const entity = value || children;
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
