import { t } from "../localization";
import Money, { anyMoney, subtractMoney } from "../shared/react/Money";
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
  direction,
  className,
}) {
  const showDiscount =
    isDiscounted ||
    anyMoney(displayableNoncashLedgerContributionAmount) ||
    anyMoney(subtractMoney(undiscountedPrice, displayableCashPrice));
  return (
    <div>
      <Stack
        direction={clsx(direction ? direction : "horizontal")}
        className={clsx(className, bold && `fw-semibold`, fs && `fs-${fs}`)}
      >
        <Money className={clsx(showDiscount && "text-success")}>
          {displayableCashPrice}
        </Money>
        {showDiscount && (
          <strike>
            <Money>{undiscountedPrice}</Money>
          </strike>
        )}
      </Stack>
      {anyMoney(discountAmount) &&
        !anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food:discount_applied", {
              discountAmount: discountAmount,
            })}
          </p>
        )}
      {!anyMoney(discountAmount) &&
        anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food:subsidy_applied", {
              subsidyAmount: displayableNoncashLedgerContributionAmount,
            })}
          </p>
        )}
      {anyMoney(discountAmount) &&
        anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food:subsidy_and_discount_applied", {
              subsidyAmount: displayableNoncashLedgerContributionAmount,
              discountAmount: displayableNoncashLedgerContributionAmount,
            })}
          </p>
        )}
    </div>
  );
}
