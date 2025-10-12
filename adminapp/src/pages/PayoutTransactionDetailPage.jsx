import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import BookTransactionDetail from "../components/BookTransactionDetail";
import DetailGrid from "../components/DetailGrid";
import ExternalLinks from "../components/ExternalLinks";
import PaymentStrategyDetailGrid from "../components/PaymentStrategyDetailGrid";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import { directEditRoute } from "../modules/resourceRoutes";
import Money from "../shared/react/Money";
import React from "react";

export default function PayoutTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="payout_transaction"
      apiGet={api.getPayoutTransaction}
      canEdit={(model) =>
        model.strategy.adminLink && directEditRoute(model.strategy.adminLink)
      }
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Status", value: model.status },
        { label: "Amount", value: <Money>{model.amount}</Money> },
        { label: "Classification", value: model.classification },
        { label: "Memo", value: model.memo },
      ]}
    >
      {(model) => [
        <PaymentStrategyDetailGrid adminDetails={model.strategy.adminDetails} />,
        model.refundedFundingTransaction && (
          <DetailGrid
            title="Refunded Transaction"
            properties={[
              {
                label: "ID",
                value: <AdminLink model={model.refundedFundingTransaction} />,
              },
              {
                label: "Created At",
                value: dayjs(model.refundedFundingTransaction.createdAt),
              },
              {
                label: "Amount",
                value: <Money>{model.refundedFundingTransaction.amount}</Money>,
              },
            ]}
          />
        ),
        <BookTransactionDetail
          title="Originated Book Transaction"
          transaction={model.originatedBookTransaction}
        />,
        <BookTransactionDetail
          title="Reversal Book Transaction"
          transaction={model.reversaldBookTransaction}
        />,
        <BookTransactionDetail
          title="Crediting Book Transaction"
          transaction={model.creditingBookTransaction}
        />,
        <ExternalLinks externalLinks={model.externalLinks} />,
        <AuditLogs auditLogs={model.auditLogs} />,
      ]}
    </ResourceDetail>
  );
}
