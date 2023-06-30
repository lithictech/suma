import { t } from "../localization";
import Money, { anyMoney } from "../shared/react/Money";
import clsx from "clsx";
import React from "react";
import { Stack } from "react-bootstrap";

export default function FoodPrice({
  // customerPrice,
  isDiscounted,
  undiscountedPrice,
  discountAmount,
  noncashLedgerContributionAmount,
  cashPrice,
  fs,
  bold,
  className,
}) {
  let showDiscount = isDiscounted || anyMoney(noncashLedgerContributionAmount);
  return (
    <div>
      <Stack
        direction="horizontal"
        className={clsx("ms-auto", className, bold && `fw-semibold`, fs && `fs-${fs}`)}
      >
        {showDiscount && (
          <strike className="me-2">
            <Money>{undiscountedPrice}</Money>
          </strike>
        )}
        <Money className={clsx(showDiscount && "text-success")}>{cashPrice}</Money>
      </Stack>
      {anyMoney(discountAmount) && (
        <p className="mb-0 small text-success">
          {t("food:discount_applied", {
            amount: discountAmount,
          })}
        </p>
      )}
      {anyMoney(noncashLedgerContributionAmount) && (
        <p className="mb-0 small text-success">
          {t("food:credit_applied", {
            amount: noncashLedgerContributionAmount,
          })}
        </p>
      )}
    </div>
  );
}
