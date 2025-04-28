import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import DetailGrid from "../components/DetailGrid";
import ExternalLinks from "../components/ExternalLinks";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function PayoutTransactionDetailPage() {
  return (
    <ResourceDetail
      resource="payout_transaction"
      apiGet={api.getPayoutTransaction}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Status", value: model.status },
        { label: "Amount", value: <Money>{model.amount}</Money> },
        { label: "Classification", value: model.classification },
        { label: "Memo", value: model.memo },
      ]}
    >
      {(model) => {
        const {
          originatedBookTransaction: originated,
          creditingBookTransaction: crediting,
        } = model;
        return [
          <DetailGrid
            title="Originated Book Transaction"
            properties={[
              { label: "ID", value: <AdminLink model={originated} /> },
              { label: "Apply At", value: dayjs(originated.applyAt) },
              { label: "Amount", value: <Money>{originated.amount}</Money> },
              {
                label: "Category",
                value: originated.associatedVendorServiceCategory?.name,
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
            ]}
          />,
          crediting && (
            <DetailGrid
              title="Crediting Book Transaction"
              properties={[
                { label: "ID", value: <AdminLink model={crediting} /> },
                { label: "Apply At", value: dayjs(crediting.applyAt) },
                { label: "Amount", value: <Money>{crediting.amount}</Money> },
                {
                  label: "Category",
                  value: crediting.associatedVendorServiceCategory?.name,
                },
                {
                  label: "Originating",
                  value: (
                    <AdminLink model={crediting.originatingLedger}>
                      {crediting.originatingLedger.adminLabel}
                    </AdminLink>
                  ),
                },
                {
                  label: "Receiving",
                  value: (
                    <AdminLink model={crediting.receivingLedger}>
                      {crediting.receivingLedger.adminLabel}
                    </AdminLink>
                  ),
                },
              ]}
            />
          ),
          <ExternalLinks externalLinks={model.externalLinks} />,
          <AuditLogs auditLogs={model.auditLogs} />,
        ];
      }}
    </ResourceDetail>
  );
}
