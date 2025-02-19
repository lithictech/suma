import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function ChargeDetailPage() {
  return (
    <ResourceDetail
      resource="charge"
      apiGet={api.getCharge}
      canEdit
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
      ]}
    >
      {(model) => (
        <>
          {model.mobilityTrip && (
            <DetailGrid
              title="Mobility Trip"
              properties={[
                { label: "ID", value: <AdminLink model={model.mobilityTrip} /> },
                {
                  label: "Created At",
                  value: dayjs(model.mobilityTrip.createdAt).format("lll"),
                },
                { label: "Vehicle ID", value: model.mobilityTrip.vehicleId },
                {
                  label: "Vendor Service",
                  value: (
                    <AdminLink model={model.mobilityTrip.vendorService}>
                      {model.mobilityTrip.vendorService?.name}
                    </AdminLink>
                  ),
                },
                {
                  label: "Started",
                  value: dayjs(model.mobilityTrip.createdAt).format("ll LTS"),
                },
                {
                  label: "Ended",
                  value: dayjs(model.mobilityTrip.createdAt).format("ll LTS"),
                },
              ]}
            />
          )}
          {model.commerceOrder && (
            <DetailGrid
              title="Commerce Order"
              properties={[
                { label: "ID", value: <AdminLink model={model.commerceOrder} /> },
                {
                  label: "Created At",
                  value: dayjs(model.commerceOrder.createdAt).format("lll"),
                },
                { label: "Status", value: model.commerceOrder.statusLabel },
              ]}
            />
          )}
          <RelatedList
            title="Book Transactions"
            headers={[
              "Id",
              "Applied",
              "Amount",
              "Originating",
              "Receiving",
              "Memo",
              "Actor",
            ]}
            rows={model.bookTransactions}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.applyAt).format("lll"),
              <Money key="amt" accounting>
                {row.amount}
              </Money>,
              <AdminLink key="originating" model={row.originatingLedger}>
                {row.originatingLedger.adminLabel}
              </AdminLink>,
              <AdminLink key="receiving" model={row.receivingLedger}>
                {row.receivingLedger.adminLabel}
              </AdminLink>,
              row.memo.en,
              <AdminLink key="actor" model={row.actor}>
                {row.actor.name}
              </AdminLink>,
            ]}
          />
          <RelatedList
            title="Funding Transactions"
            rows={model.associatedFundingTransactions}
            headers={["Id", "Created", "Status", "Amount", "Originating Payment Account"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink key="id" model={row} />,
              dayjs(row.createdAt).format("lll"),
              row.status,
              <Money key="amt">{row.amount}</Money>,
              <AdminLink model={row.originatingPaymentAccount}>
                {row.originatingPaymentAccount.displayName}
              </AdminLink>,
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
