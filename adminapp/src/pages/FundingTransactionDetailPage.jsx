import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import DetailGrid from "../components/DetailGrid";
import ExternalLinks from "../components/ExternalLinks";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import React from "react";

export default function FundingTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="funding_transaction"
      apiGet={api.getFundingTransaction}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Originating Payment Account",
          value: (
            <AdminLink model={model.originatingPaymentAccount}>
              {model.originatingPaymentAccount.displayName}
            </AdminLink>
          ),
        },
        { label: "Status", value: model.status },
        { label: "Amount", value: <Money>{model.amount}</Money> },
        model.refundedAmount.cents > 0 && {
          label: "Refunded Amount",
          value: <Money>{model.refundedAmount}</Money>,
        },
        { label: "Memo", value: model.memo },
      ]}
    >
      {(model) => {
        const originated = model.originatedBookTransaction;
        return [
          <DetailGrid
            title="Book Transaction"
            properties={[
              { label: "ID", value: <AdminLink model={originated} /> },
              { label: "Apply At", value: dayjs(originated.applyAt) },
              { label: "Amount", value: <Money>{originated.amount}</Money> },
              {
                label: "Category",
                value: originated.associatedVendorServiceCategory.name,
              },
              {
                label: "Originating",
                value: (
                  <AdminLink model={originated.originatingLedger}>
                    {originated.originatingLedger.adminLabel}
                  </AdminLink>
                ),
              },
              {
                label: "Receiving",
                value: (
                  <AdminLink model={originated.receivingLedger}>
                    {originated.receivingLedger.adminLabel}
                  </AdminLink>
                ),
              },
              {
                label: "Actor",
                hideEmpty: true,
                value: originated.actor ? (
                  <AdminLink model={originated.actor}>{originated.actor.name}</AdminLink>
                ) : undefined,
              },
            ]}
          />,
          <RelatedList
            title="Refund Payout Transactions"
            rows={model.refundPayoutTransactions}
            headers={["Id", "Created", "Amount"]}
            keyRowAttr="id"
            addNewLabel={model.canRefund && "Refund this transaction"}
            addNewLink={
              model.canRefund &&
              `/funding-transaction/${
                model.id
              }/refund?refundableAmount=${encodeURIComponent(
                JSON.stringify(model.refundableAmount)
              )}`
            }
            addNewRole="payoutTransaction"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              formatDate(row.createdAt),
              <Money key="amt">{row.amount}</Money>,
            ]}
          />,
          <ExternalLinks externalLinks={model.externalLinks} />,
          <AuditLogs auditLogs={model.auditLogs} />,
        ];
      }}
    </ResourceDetail>
  );
}
