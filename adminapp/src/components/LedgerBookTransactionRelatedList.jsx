import { dayjs } from "../modules/dayConfig";
import { scaleMoney } from "../shared/money";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function LedgerBookTransactionsRelatedList({ ledger, title, key, rows }) {
  return (
    <RelatedList
      title={title}
      key={key || null}
      headers={[
        "Id",
        "Created",
        "Applied",
        "Amount",
        "Category",
        "Originating",
        "Receiving",
      ]}
      rows={rows}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.createdAt).format("lll"),
        dayjs(row.applyAt).format("lll"),
        <Money key="amt" accounting>
          {row.originatingLedger.id === ledger.id
            ? scaleMoney(row.amount, -1)
            : row.amount}
        </Money>,
        row.associatedVendorServiceCategory?.name,
        <AdminLink key="originating" model={row.originatingLedger}>
          {row.originatingLedger.adminLabel}
        </AdminLink>,
        <AdminLink key="receiving" model={row.receivingLedger}>
          {row.receivingLedger.adminLabel}
        </AdminLink>,
      ]}
    />
  );
}
