import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import Money from "../shared/react/Money";
import React from "react";

export default function MobilityTripDetailPage() {
  return (
    <ResourceDetail
      resource="mobility_trip"
      apiGet={api.getMobilityTrip}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Member",
          value: <AdminLink model={model.member}>{model.member?.name}</AdminLink>,
        },
        {
          label: "Vendor",
          value: (
            <AdminLink model={model.vendorService.vendor}>
              {model.vendorService.vendor?.name}
            </AdminLink>
          ),
        },
        {
          label: "Vendor Service",
          value: (
            <AdminLink model={model.vendorService}>{model.vendorService?.name}</AdminLink>
          ),
        },
        { label: "Vehicle ID", value: model.vehicleId },
        { label: "Opaque ID", value: model.opaqueId },
        { label: "External Trip ID", value: model.externalTripId },
        { label: "Started At", value: formatDate(model.beganAt, { template: "ll LTS" }) },
        {
          label: "Ended At",
          value: formatDate(model.endedAt, { template: "ll LTS", default: "Ongoing" }),
        },
        { label: "Start Lat", value: model.beginLat },
        { label: "Start Lng", value: model.beginLng },
        { label: "End Lat", value: model.endLat, hideEmpty: true },
        { label: "End Lng", value: model.endLng, hideEmpty: true },
        { label: "Total Cost", value: <Money>{model.totalCost}</Money> },
        { label: "Discount Amount", value: <Money>{model.discountAmount}</Money> },
      ]}
    >
      {(model) => (
        <>
          {model.charge && (
            <DetailGrid
              title="Charge"
              properties={[
                { label: "ID", value: <AdminLink model={model.charge} /> },
                {
                  label: "Created At",
                  value: formatDate(model.charge.createdAt),
                },
                { label: "Opaque ID", value: model.charge.opaqueId },
                {
                  label: "Discounted Subtotal",
                  value: <Money>{model.charge.discountedSubtotal}</Money>,
                },
                {
                  label: "Undiscounted Subtotal",
                  value: <Money>{model.charge.undiscountedSubtotal}</Money>,
                },
              ]}
            />
          )}
          <DetailGrid
            title="Rate"
            properties={[
              { label: "Id", value: model.rate.id },
              { label: "Name", value: model.rate.name },
              { label: "Created", value: formatDate(model.rate.createdAt) },
              { label: "Unit Amount", value: <Money>{model.rate.unitAmount}</Money> },
              { label: "Surcharge", value: <Money>{model.rate.surcharge}</Money> },
              { label: "Unit Offset", value: model.rate.unitOffset },
              {
                label: "Undiscounted Amount",
                value: <Money>{model.rate.undiscountedAmount}</Money>,
              },
              {
                label: "Undiscounted Surcharge",
                value: <Money>{model.rate.undiscountedSurcharge}</Money>,
              },
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
