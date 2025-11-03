import formatDate from "../modules/formatDate";
import AdminLink from "./AdminLink";
import DetailGrid from "./DetailGrid";
import React from "react";

export default function MobilityTripDetailGrid({ model }) {
  if (!model) {
    return;
  }
  return (
    <DetailGrid
      title="Mobility Trip"
      properties={[
        { label: "ID", value: <AdminLink model={model} /> },
        {
          label: "Created At",
          value: formatDate(model.createdAt),
        },
        { label: "Vehicle ID", value: model.vehicleId },
        {
          label: "Vendor Service",
          value: (
            <AdminLink model={model.vendorService}>
              {model.vendorService.internalName}
            </AdminLink>
          ),
        },
        {
          label: "Rate",
          value: (
            <AdminLink model={model.vendorServiceRate}>
              {model.vendorServiceRate.internalName}
            </AdminLink>
          ),
        },
        {
          label: "Started",
          value: formatDate(model.createdAt, { template: "ll LTS" }),
        },
        {
          label: "Ended",
          value: formatDate(model.createdAt, { template: "ll LTS" }),
        },
      ]}
    />
  );
}
