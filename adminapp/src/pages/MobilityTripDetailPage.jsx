import api from "../api";
import AdminLink from "../components/AdminLink";
import ChargeDetailGrid from "../components/ChargeDetailGrid";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
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
            <AdminLink model={model.vendorService}>
              {model.vendorService?.internalName}
            </AdminLink>
          ),
        },
        {
          label: "Service Rate",
          value: (
            <AdminLink model={model.vendorServiceRate}>
              {model.vendorServiceRate?.internalName}
            </AdminLink>
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
      ]}
    >
      {(model) => [<ChargeDetailGrid isDetailGrid model={model.charge} />]}
    </ResourceDetail>
  );
}
