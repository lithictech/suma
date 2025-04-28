import api from "../api";
import AdminLink from "../components/AdminLink";
import LedgerBookTransactionsRelatedList from "../components/LedgerBookTransactionRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function PaymentLedgerDetailPage() {
  return (
    <ResourceDetail
      resource="ledger"
      apiGet={api.getPaymentLedger}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Name", value: model.name },
        { label: "Currency", value: model.currency },
        { label: "Balance", value: <Money>{model.balance}</Money> },
        {
          label: "Member",
          value: model.isPlatformAccount ? (
            "(Platform)"
          ) : (
            <AdminLink model={model.member}>{model.member.name}</AdminLink>
          ),
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Vendor Service Categories"
          headers={["Id", "Name", "Slug"]}
          rows={model.vendorServiceCategories}
          keyRowAttr="id"
          toCells={(row) => [row.id, row.name, row.slug]}
        />,
        <LedgerBookTransactionsRelatedList
          ledger={model}
          title="Book Transactions"
          rows={model.combinedBookTransactions}
        />,
      ]}
    </ResourceDetail>
  );
}
