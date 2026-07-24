import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import EligibilityRequirementsRelatedList from "../components/EligibilityRequirementsRelatedList";
import RelatedListRemote, { ListTitle } from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import SimpleTable from "../components/SimpleTable";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { formatMoney, intToMoney } from "../shared/money";
import { CardContent, Card } from "@mui/material";
import React from "react";

export default function PaymentTriggerDetailPage() {
  const now = dayjs();
  return (
    <ResourceDetail
      resource="payment_trigger"
      apiGet={api.getPaymentTrigger}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Label", value: model.label },
        { label: "Match Multiplier", value: model.matchMultiplier },
        { label: "Match Percentage", value: Math.round(model.matchFraction * 100) + "%" },
        {
          label: "Unmatched Amount",
          value: formatMoney(intToMoney(model.unmatchedAmountCents, "USD")),
        },
        {
          label: "Max Subsidy",
          value: formatMoney(intToMoney(model.maximumCumulativeSubsidyCents, "USD")),
        },
        { label: "Act as Credit", value: model.actAsCredit },
        { label: "Memo (En)", value: model.memo.en },
        { label: "Memo (Es)", value: model.memo.es },
        {
          label: "Originating Ledger",
          value: (
            <AdminLink model={model.originatingLedger}>
              {model.originatingLedger.label}
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
      {(model) => [
        <EligibilityRequirementsRelatedList model={model} type="payment_trigger" />,
        <Card>
          <CardContent>
            <ListTitle title="Active During" count={model.activeDuring.length} />
            <SimpleTable
              rows={model.activeDuring}
              headers={["Start", "End"]}
              toCells={(row) => [formatDate(row.start), formatDate(row.end)]}
              rowSx={(row) =>
                dayjs(row.end).isBefore(now)
                  ? { "& .MuiTableCell-root": { color: "text.disabled" } }
                  : {}
              }
              tableProps={{ size: "small" }}
            />
          </CardContent>
        </Card>,
        <RelatedListRemote
          title="Executions"
          collection={model.executions}
          keyRowAttr="id"
          headers={["Id", "At", "To"]}
          toCells={(row) => [
            <AdminLink key="bookx" model={row}>
              {row.bookTransactionId}
            </AdminLink>,
            formatDate(row.at),
            <AdminLink key="recledger" model={row}>
              {row.receivingLedger.label}
            </AdminLink>,
          ]}
        />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}
