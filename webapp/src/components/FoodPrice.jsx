import { t } from "../localization";
import Money, { anyMoney } from "../shared/react/Money";
import clsx from "clsx";
import React from "react";
import Stack from "react-bootstrap/Stack";

export default function FoodPrice({
  isDiscounted,
  undiscountedPrice,
  discountAmount,
  displayableNoncashLedgerContributionAmount,
  displayableCashPrice,
  fs,
  bold,
  className,
}) {
  const showDiscount =
    isDiscounted || anyMoney(displayableNoncashLedgerContributionAmount);
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
        <Money className={clsx(showDiscount && "text-success")}>
          {displayableCashPrice}
        </Money>
      </Stack>
      {anyMoney(discountAmount) && (
        <p className="mb-0 small text-success">
          {t("food:discount_applied", {
            amount: discountAmount,
          })}
        </p>
      )}
      {anyMoney(displayableNoncashLedgerContributionAmount) && (
        <p className="mb-0 small text-success">
          {t("food:credit_applied", {
            amount: displayableNoncashLedgerContributionAmount,
          })}
        </p>
      )}
    </div>
  );
}
