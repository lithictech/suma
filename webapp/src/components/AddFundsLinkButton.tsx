import config from "../config";
import { t } from "../localization";
import Button from "../ui/Button";
import React from "react";

export default function AddFundsLinkButton() {
  if (!config.featureAddFunds) {
    return null;
  }
  return (
    <Button variant="outline" href="/funding" size="sm">
      {t("payments.add_funds")}
    </Button>
  );
}
