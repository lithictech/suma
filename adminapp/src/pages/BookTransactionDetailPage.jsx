import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import ResourceDetail, { ResourceSummary } from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import React from "react";

export default function BookTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="book_transaction"
      apiGet={api.getBookTransaction}
      properties={(model) => [
        ...resourceDetailCommonFields(model),
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
              {model.originatingLedger.label}
            </AdminLink>
          ),
        },
        {
          label: "Receiving",
          value: (
            <AdminLink model={model.receivingLedger}>
              {model.receivingLedger.label}
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
      {(model) => [
        relatedExternalTransaction(
          "Originating Funding Transaction",
          model.originatingFundingTransaction
        ),
        relatedExternalTransaction(
          "Originating Payout Transaction",
          model.originatingPayoutTransaction
        ),
        relatedExternalTransaction(
          "Credited Payout Transaction",
          model.creditedPayoutTransaction
        ),
        model.chargeContributedTo && (
          <ResourceSummary>
            <DetailGrid
              title="Charges Contributed To"
              properties={[
                { label: "Id", value: <AdminLink model={model.chargeContributedTo} /> },
                { label: "At", value: formatDate(model.chargeContributedTo.createdAt) },
                {
                  label: "Undiscounted Total",
                  value: <Money>{model.chargeContributedTo.undiscountedSubtotal}</Money>,
                },
                { label: "Opaque ID", value: model.chargeContributedTo.opaqueId },
              ]}
            />
          </ResourceSummary>
        ),
      ]}
    </ResourceDetail>
  );
}

function relatedExternalTransaction(title, model) {
  if (!model) {
    return null;
  }
  // Must return ResourceSummary unwrapped so child detection for layout works.
  return (
    <ResourceSummary>
      <DetailGrid
        title={title}
        properties={[
          {
            label: "Id",
            value: <AdminLink model={model} />,
          },
          {
            label: "Created",
            value: formatDate(model.createdAt),
          },
          { label: "Status", value: model.status },
          {
            label: "Amount",
            value: <Money>{model.amount}</Money>,
          },
        ]}
      />
    </ResourceSummary>
  );
}
