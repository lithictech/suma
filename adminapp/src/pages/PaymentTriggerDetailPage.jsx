import api from "../api";
import AdminLink from "../components/AdminLink";
import Programs from "../components/Programs";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { formatMoney, intToMoney } from "../shared/money";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

export default function PaymentTriggerDetailPage() {
  return (
    <ResourceDetail
      resource="payment_trigger"
      apiGet={api.getPaymentTrigger}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Label", value: model.label },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Starting", value: dayjs(model.activeDuringBegin) },
        { label: "Ending", value: dayjs(model.activeDuringEnd) },
        { label: "Match Multiplier", value: model.matchMultiplier },
        {
          label: "Max Subsidy",
          value: formatMoney(intToMoney(model.maximumCumulativeSubsidyCents)),
        },
        { label: "Memo (En)", value: model.memo.en },
        { label: "Memo (Es)", value: model.memo.es },
        {
          label: "Originating Ledger",
          value: (
            <AdminLink model={model.originatingLedger}>
              {model.originatingLedger.adminLabel}
            </AdminLink>
          ),
        },
        { label: "Receiving Ledger", value: model.receivingLedgerName },
        {
          label: "Contribution Text (En)",
          value: model.receivingLedgerContributionText.en,
        },
        {
          label: "Contribution Text (Es)",
          value: model.receivingLedgerContributionText.es,
        },
      ]}
    >
      {(model, setModel) => (
        <>
          <Programs
            resource="payment_trigger"
            programs={model.programs}
            modelId={model.id}
            replaceModelData={setModel}
            makeUpdateRequest={api.updatePaymentTriggerPrograms}
          />
          <RelatedList
            title="Executions"
            rows={model.executions}
            keyRowAttr="id"
            headers={["Id", "At", "To"]}
            toCells={(row) => [
              <AdminLink key="bookx" model={row}>
                {row.bookTransactionId}
              </AdminLink>,
              formatDate(row.at),
              <AdminLink key="recledger" model={row}>
                {row.receivingLedger.adminLabel}
              </AdminLink>,
            ]}
          />
          <RelatedList
            title="Vendor Configurations"
            rows={model.configurations}
            keyRowAttr="id"
            headers={[
              "Id",
              "Created",
              "Vendor",
              "App Install Link",
              "Uses Email",
              "Uses SMS",
              "Enabled",
            ]}
            toCells={(row) => [
              row.id,
              formatDate(row.createdAt),
              <AdminLink key={row.vendor.name} model={row.vendor}>
                {row.vendor.name}
              </AdminLink>,
              <SafeExternalLink key={1} href={row.appInstallLink}>
                {row.appInstallLink}
              </SafeExternalLink>,
              row.usesEmail ? "Yes" : "No",
              row.usesSms ? "Yes" : "No",
              row.enabled ? "Yes" : "No",
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
