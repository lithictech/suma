import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import BookTransactionDetail from "../components/BookTransactionDetail";
import ExternalLinks from "../components/ExternalLinks";
import PaymentStrategyDetailGrid from "../components/PaymentStrategyDetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { directEditRoute } from "../modules/resourceRoutes";
import Money from "../shared/react/Money";
import React from "react";

export default function FundingTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="funding_transaction"
      apiGet={api.getFundingTransaction}
      canEdit={(model) =>
        model.strategy.adminLink && directEditRoute(model.strategy.adminLink)
      }
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
        return [
          <PaymentStrategyDetailGrid adminDetails={model.strategy.adminDetails} />,
          <BookTransactionDetail
            title="Originated Book Transaction"
            transaction={model.originatedBookTransaction}
          />,
          <BookTransactionDetail
            title="Reversal Book Transaction"
            transaction={model.reversaldBookTransaction}
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
