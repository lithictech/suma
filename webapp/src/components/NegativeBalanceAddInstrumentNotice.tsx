import { t } from "../localization";
import { scaleMoney } from "../modules/money";
import useUser from "../state/useUser";
import Alert from "../ui/Alert";

export default function NegativeBalanceAddInstrumentNotice() {
  const { user } = useUser();

  if (!user.chargeableCashBalance) {
    return null;
  }

  const balance = scaleMoney(user.chargeableCashBalance, -1);

  return (
    <Alert variant="warning">
      {t("payments.negative_balance_add_instrument_notice", {
        amount: balance,
      })}
    </Alert>
  );
}
