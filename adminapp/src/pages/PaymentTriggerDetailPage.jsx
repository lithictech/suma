import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import EligibilityRequirementsRelatedList from "../components/EligibilityRequirementsRelatedList";
import Link from "../components/Link";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { formatMoney, intToMoney } from "../shared/money";
import useUrlMarshal from "../shared/react/useUrlMarshal";
import HorizontalSplitIcon from "@mui/icons-material/HorizontalSplit";
import React from "react";

export default function PaymentTriggerDetailPage() {
  const { marshalToUrl } = useUrlMarshal();
  return (
    <ResourceDetail
      resource="payment_trigger"
      apiGet={api.getPaymentTrigger}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Label", value: model.label },
        { label: "Starting", value: dayjs(model.activeDuringBegin) },
        { label: "Ending", value: dayjs(model.activeDuringEnd) },
        {
          label: "Subdivide",
          value: (
            <Link
              to={`/payment-trigger/${model.id}/subdivide?${marshalToUrl(
                "model",
                model
              )}`}
            >
              <HorizontalSplitIcon sx={{ verticalAlign: "middle", marginRight: 1 }} />
              Subdivide
            </Link>
          ),
        },
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
