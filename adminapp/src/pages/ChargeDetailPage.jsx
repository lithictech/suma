import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import React from "react";

export default function ChargeDetailPage() {
  return (
    <ResourceDetail
      resource="charge"
      apiGet={api.getCharge}
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
                  value: formatDate(model.mobilityTrip.createdAt),
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
                  value: formatDate(model.mobilityTrip.createdAt, { template: "ll LTS" }),
                },
                {
                  label: "Ended",
                  value: formatDate(model.mobilityTrip.createdAt, { template: "ll LTS" }),
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
                  value: formatDate(model.commerceOrder.createdAt),
                },
                { label: "Status", value: model.commerceOrder.statusLabel },
              ]}
            />
          )}
          <RelatedList
            title="Line Items"
            headers={["Id", "Amount", "Memo", "Originating", "Receiving"]}
            rows={model.lineItems}
            keyRowAttr="id"
            toCells={(row) => [
              row.id,
              <Money key="amt" accounting>
                {row.amount}
              </Money>,
              row.memo.en,
              row.bookTransaction && (
                <AdminLink key="originating" model={row.bookTransaction}>
                  {row.bookTransaction.originatingLedger.adminLabel}
                </AdminLink>
              ),
              row.bookTransaction && (
                <AdminLink key="receiving" model={row.bookTransaction}>
                  {row.bookTransaction.receivingLedger.adminLabel}
                </AdminLink>
              ),
            ]}
          />
          <RelatedList
            title="Funding Transactions"
            rows={model.associatedFundingTransactions}
            headers={["Id", "Created", "Status", "Amount", "Originating Payment Account"]}
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
          />
        </>
      )}
    </ResourceDetail>
  );
}
