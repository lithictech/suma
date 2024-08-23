import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function BookTransactionListPage() {
  return (
    <ResourceList
      resource="book_transaction"
      apiList={api.getBookTransactions}
      toCreate="/book-transaction/new"
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
          id: "apply_at",
          label: "Apply At",
          align: "center",
          sortable: true,
          render: (c) => dayjs(c.applyAt).format("lll"),
        },
        {
          id: "amount",
          label: "Amount",
          align: "center",
          render: (c) => <Money>{c.amount}</Money>,
        },
        {
          id: "memo",
          label: "Memo",
          align: "center",
          render: (c) => c.memo.en,
        },
        {
          id: "category",
          label: "Category",
          align: "center",
          render: (c) => c.associatedVendorServiceCategory?.name,
        },
        {
          id: "originating",
          label: "Originating",
          align: "center",
          render: (c) => (
            <AdminLink model={c.originatingLedger}>
              {c.originatingLedger.adminLabel}
            </AdminLink>
          ),
        },
        {
          id: "receiving",
          label: "Receiving",
          align: "center",
          render: (c) => (
            <AdminLink model={c.receivingLedger}>
              {c.receivingLedger.adminLabel}
            </AdminLink>
          ),
        },
      ]}
    />
  );
}
