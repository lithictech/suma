import { t } from "../localization";
import { anyMoney, subtractMoney } from "../modules/money";
import Stack from "../ui/Stack";
import Money from "../uir/Money";
import clsx from "clsx";

interface FoodPriceProps {
  isDiscounted?: boolean;
  undiscountedPrice: Money;
  discountAmount?: Money;
  displayableNoncashLedgerContributionAmount?: Money;
  displayableCashPrice: Money;
  vendorName?: string;
  fs?: number | string;
  bold?: boolean;
  direction?: string;
  className?: string;
}

export default function FoodPrice({
  isDiscounted,
  undiscountedPrice,
  discountAmount,
  displayableNoncashLedgerContributionAmount,
  displayableCashPrice,
  vendorName,
  fs,
  bold,
  direction,
  className,
}: FoodPriceProps) {
  const showDiscount =
    isDiscounted ||
    anyMoney(displayableNoncashLedgerContributionAmount) ||
    anyMoney(subtractMoney(undiscountedPrice, displayableCashPrice));
  return (
    <div>
      <Stack
        direction={
          clsx(direction ? direction : "horizontal") as "horizontal" | "vertical"
        }
        className={clsx(className, bold && `fw-semibold`, fs && `fs-${fs}`)}
      >
        <Money className={clsx(showDiscount && "text-success")}>
          {displayableCashPrice}
        </Money>
        {showDiscount && (
          <s>
            <Money>{undiscountedPrice}</Money>
          </s>
        )}
      </Stack>
      {anyMoney(discountAmount) &&
        !anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food.discount_applied", {
              discountAmount: discountAmount,
              vendorName: vendorName,
            })}
          </p>
        )}
      {!anyMoney(discountAmount) &&
        anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food.subsidy_applied", {
              subsidyAmount: displayableNoncashLedgerContributionAmount,
            })}
          </p>
        )}
      {anyMoney(discountAmount) &&
        anyMoney(displayableNoncashLedgerContributionAmount) && (
          <p className="mb-0 small text-success">
            {t("food.subsidy_and_discount_applied", {
              discountAmount: discountAmount,
              vendorName: vendorName,
              subsidyAmount: displayableNoncashLedgerContributionAmount,
            })}
          </p>
        )}
    </div>
  );
}
