import api from "../api";
import AdminLink from "../components/AdminLink";
import DetailGrid from "../components/DetailGrid";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
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
        { label: "External Trip ID", value: model.externalTripId },
        { label: "Started At", value: dayjs(model.beganAt).format("ll LTS") },
        { label: "Ended At", value: dayjs(model.endedAt).format("ll LTS") },
        { label: "Start Lat", value: model.beginLat },
        { label: "Start Lng", value: model.beginLng },
        { label: "End Lat", value: model.endLat },
        { label: "End Lng", value: model.endLng },
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
                  value: dayjs(model.charge.createdAt).format("lll"),
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
              { label: "Created", value: dayjs(model.rate.createdAt).format("lll") },
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
