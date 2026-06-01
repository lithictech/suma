import { dayjs } from "../modules/dayConfig";
import { scaleMoney } from "../shared/money";
import Money from "../shared/react/Money";
import AdminLink from "./AdminLink";
import ForwardTo from "./ForwardTo";
import RelatedListRemote from "./RelatedListRemote";
import React from "react";

export default function LedgerBookTransactionsRelatedList({ ledger, title, collection }) {
  return (
    <RelatedListRemote
      title={
        <span>
          {title} <ForwardTo to={ledger.adminLink} />
        </span>
      }
      headers={["Id", "Applied", "Amount", "Originating", "Receiving"]}
      collection={collection}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        dayjs(row.applyAt).format("lll"),
        <Money key="amt" accounting>
          {row.originatingLedger.id === ledger.id
            ? scaleMoney(row.amount, -1)
            : row.amount}
        </Money>,
        <AdminLink key="originating" model={row.originatingLedger}>
          {row.originatingLedger.label}
        </AdminLink>,
        <AdminLink key="receiving" model={row.receivingLedger}>
          {row.receivingLedger.label}
        </AdminLink>,
      ]}
    />
  );
}
