import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function MobilityTripListPage() {
  return (
    <ResourceList
      resource="mobility_trip"
      apiList={api.getMobilityTrips}
      canSearch
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member.name}</AdminLink>,
        },
        {
          id: "vendor",
          label: "Vendor",
          align: "left",
          render: (c) => (
            <AdminLink model={c.vendorService.vendor}>
              {c.vendorService.vendor.name}
            </AdminLink>
          ),
        },
        {
          id: "vendor_service",
          label: "Vendor Service",
          align: "left",
          render: (c) => (
            <AdminLink model={c.vendorService}>{c.vendorService.name}</AdminLink>
          ),
        },
        {
          id: "vehicle_id",
          label: "Vehicle ID",
          align: "left",
          render: (c) => c.vehicleId,
        },
        {
          id: "began_at",
          label: "Began",
          align: "center",
          render: (c) => dayjs(c.beganAt).format("ll LTS"),
        },
        {
          id: "ended_at",
          label: "Ended",
          align: "center",
          render: (c) => dayjs(c.endedAt).format("ll LTS"),
        },
        {
          id: "total_cost",
          label: "Total Cost",
          align: "center",
          render: (c) => <Money>{c.totalCost}</Money>,
        },
      ]}
    />
  );
}
