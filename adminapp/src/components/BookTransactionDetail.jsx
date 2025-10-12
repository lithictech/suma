import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import React from "react";

export default function BookTransactionDetail({ title, transaction }) {
  if (!transaction) {
    return null;
  }
  return (
    <DetailGrid
      title={title}
      properties={[
        { label: "ID", value: <AdminLink model={transaction} /> },
        { label: "Apply At", value: dayjs(transaction.applyAt) },
        { label: "Amount", value: <Money>{transaction.amount}</Money> },
        {
          label: "Category",
          value: transaction.associatedVendorServiceCategory.name,
        },
        {
          label: "Originating",
          value: (
            <AdminLink model={transaction.originatingLedger}>
              {transaction.originatingLedger.adminLabel}
            </AdminLink>
          ),
        },
        {
          label: "Receiving",
          value: (
            <AdminLink model={transaction.receivingLedger}>
              {transaction.receivingLedger.adminLabel}
            </AdminLink>
          ),
        },
        {
          label: "Actor",
          hideEmpty: true,
          value: transaction.actor ? (
            <AdminLink model={transaction.actor}>{transaction.actor.name}</AdminLink>
          ) : undefined,
        },
      ]}
    />
  );
}
