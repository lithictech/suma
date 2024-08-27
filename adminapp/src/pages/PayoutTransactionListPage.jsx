import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function PayoutTransactionListPage() {
  return (
    <ResourceList
      resource="payout_transaction"
      apiList={api.getPayoutTransactions}
      canSearch
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "created_at",
          label: "Created",
          align: "center",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "amount",
          label: "Amount",
          align: "center",
          render: (c) => <Money>{c.amount}</Money>,
        },
        {
          id: "status",
          label: "Status",
          align: "center",
          render: (c) => c.status,
        },
        {
          id: "classification",
          label: "Type",
          align: "center",
          render: (c) => c.classification,
        },
        {
          id: "originating",
          label: "Originating",
          align: "center",
          render: (c) => (
            <AdminLink model={c.originatingPaymentAccount}>
              {c.originatingPaymentAccount.displayName}
            </AdminLink>
          ),
        },
      ]}
    />
  );
}
