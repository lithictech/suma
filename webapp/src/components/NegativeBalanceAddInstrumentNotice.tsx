import { t } from "../localization";
import { scaleMoney } from "../modules/money";
import useUser from "../state/useUser";
import TODO from "./TODO";

export default function NegativeBalanceAddInstrumentNotice() {
  const { user } = useUser();

  if (!user!.chargeableCashBalance) {
    return null;
  }

  const balance = scaleMoney(user!.chargeableCashBalance, -1);

  return (
    <TODO variant="warning">
      {t("payments.negative_balance_add_instrument_notice", {
        amount: balance,
      })}
    </TODO>
  );
}
