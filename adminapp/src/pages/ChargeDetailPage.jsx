import api from "../api";
import AdminLink from "../components/AdminLink";
import CommerceOrderDetailGrid from "../components/CommerceOrderDetailGrid";
import MobilityTripDetailGrid from "../components/MobilityTripDetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { anyMoney } from "../shared/money";
import Money from "../shared/react/Money";
import React from "react";

export default function ChargeDetailPage() {
  return (
    <ResourceDetail
      resource="charge"
      apiGet={api.getCharge}
      canEdit={false}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member?.name}</AdminLink>,
        },
        {
          label: "Opaque Id",
          value: model.opaqueId,
        },
        {
          label: "Discounted Subtotal / Total Cost",
          value: <Money>{model.discountedSubtotal}</Money>,
        },
        {
          label: "Undiscounted Subtotal",
          value: <Money>{model.undiscountedSubtotal}</Money>,
        },
        {
          label: "Cash Paid from Ledger",
          value: <Money>{model.cashPaidFromLedger}</Money>,
        },
        {
          label: "Non-Cash Paid from Ledger",
          value: <Money>{model.noncashPaidFromLedger}</Money>,
        },
        anyMoney(model.offPlatformAmount) && {
          label: "Off-Platform Amount",
          value: <Money>{model.offPlatformAmount}</Money>,
        },
      ]}
    >
      {(model) => [
        <MobilityTripDetailGrid isDetailGrid model={model.mobilityTrip} />,
        <CommerceOrderDetailGrid isDetailGrid model={model.commerceOrder} />,
        <RelatedList
          title="Line Items"
          headers={["Id", "Amount", "Memo"]}
          rows={model.lineItems}
          keyRowAttr="id"
          toCells={(row) => [
            row.id,
            <Money key="amt" accounting>
              {row.amount}
            </Money>,
            row.memo.en,
          ]}
        />,
        <RelatedList
          title="Funding Transactions"
          rows={model.associatedFundingTransactions}
          headers={["Id", "Created", "Status", "Amount", "Originating Account"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            formatDate(row.createdAt),
            row.status,
            <Money key="amt">{row.amount}</Money>,
            <AdminLink model={row.originatingPaymentAccount}>
              {row.originatingPaymentAccount.displayName}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Book Transactions"
          rows={model.contributingBookTransactions}
          headers={["Id", "Amount", "Receiving Ledger"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <Money key="amt">{row.amount}</Money>,
            <AdminLink model={row.receivingLedger}>
              {row.receivingLedger.adminLabel}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
