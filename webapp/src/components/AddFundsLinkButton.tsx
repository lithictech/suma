import RLink from "../components/RLink";
import config from "../config";
import { t } from "../localization";
import Button from "../ui/Button.jsx";
import React from "react";

export default function AddFundsLinkButton() {
  if (!config.featureAddFunds) {
    return null;
  }
  return (
    <Button variant="outline-success" href="/funding" as={RLink} size="sm">
      {t("payments.add_funds")}
    </Button>
  );
}
