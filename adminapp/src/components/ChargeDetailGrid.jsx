import { anyMoney } from "../shared/money";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import React from "react";

export default function ChargeDetailGrid({ model }) {
  if (!model) {
    return null;
  }
  return (
    <DetailGrid
      title="Charge"
      properties={[
        { label: "ID", value: <AdminLink model={model} /> },
        {
          label: "Discounted Subtotal / Total Cost",
          value: <Money>{model.discountedSubtotal}</Money>,
        },
        {
          label: "Undiscounted Subtotal",
          value: <Money>{model.undiscountedSubtotal}</Money>,
        },
        {
          label: "Cash Paid from Ledger",
          value: <Money>{model.cashPaidFromLedger}</Money>,
        },
        {
          label: "Non-Cash Paid from Ledger",
          value: <Money>{model.noncashPaidFromLedger}</Money>,
        },
        anyMoney(model.offPlatformAmount) && {
          label: "Off-Platform Amount",
          value: <Money>{model.offPlatformAmount}</Money>,
        },
      ]}
    />
  );
}
