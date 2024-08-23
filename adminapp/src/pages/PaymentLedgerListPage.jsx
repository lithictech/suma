import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Money from "../shared/react/Money";
import React from "react";

export default function PaymentLedgerListPage() {
  return (
    <ResourceList
      resource="ledger"
      apiList={api.getPaymentLedgers}
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
          id: "name",
          label: "Name",
          sortable: true,
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "member",
          label: "Member",
          render: (c) =>
            c.isPlatformAccount ? (
              "(Platform)"
            ) : (
              <AdminLink model={c.member}>{c.member?.name}</AdminLink>
            ),
        },
        {
          id: "balance",
          label: "Balance",
          render: (c) => <Money>{c.balance}</Money>,
        },
      ]}
    />
  );
}
