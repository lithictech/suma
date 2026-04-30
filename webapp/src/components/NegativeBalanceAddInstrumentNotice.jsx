import { t } from "../localization/index.jsx";
import { scaleMoney } from "../shared/money.js";
import useUser from "../state/useUser.jsx";
import React from "react";
import Alert from "react-bootstrap/Alert";

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
