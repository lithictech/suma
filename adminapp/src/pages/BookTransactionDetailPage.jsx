import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function BookTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="book_transaction"
      apiGet={api.getBookTransaction}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Apply At", value: dayjs(model.applyAt) },
        { label: "Amount", value: <Money>{model.amount}</Money> },
        { label: "Category", value: model.associatedVendorServiceCategory?.name },
        { label: "External Id", value: model.opaqueId },
        { label: `Memo (En)`, value: model.memo.en },
        { label: `Memo (Es)`, value: model.memo.es },
        {
          label: "Originating",
          value: (
            <AdminLink model={model.originatingLedger}>
              {model.originatingLedger.adminLabel}
            </AdminLink>
          ),
        },
        {
          label: "Receiving",
          value: (
            <AdminLink model={model.receivingLedger}>
              {model.receivingLedger.adminLabel}
            </AdminLink>
          ),
        },
        model.triggeredBy && {
          label: "Triggered by",
          value: (
            <AdminLink model={model.triggeredBy}>{model.triggeredBy.label}</AdminLink>
          ),
        },
        {
          label: "Actor",
          hideEmpty: true,
          value: model.actor ? (
            <AdminLink model={model.actor}>{model.actor.name}</AdminLink>
          ) : undefined,
        },
      ]}
    >
      {(model) => (
        <>
          <RelatedList
            title="Funding Transactions"
            rows={model.fundingTransactions}
            headers={["Id", "Created", "Status", "Amount"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.status,
              <Money key="amt">{row.amount}</Money>,
            ]}
          />
          <RelatedList
            title="Charges"
            headers={["Id", "At", "Undiscounted Total", "Opaque Id"]}
            rows={model.charges}
            toCells={(row) => [
              row.id,
              dayjs(row.createdAt).format("lll"),
              <Money key={3}>{row.undiscountedSubtotal}</Money>,
              row.opaqueId,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
