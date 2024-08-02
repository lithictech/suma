import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function VendorServiceListPage() {
  return (
    <ResourceList
      apiList={api.getVendorServices}
      title="Vendor Services"
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
          id: "external_name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "vendor",
          label: "Vendor",
          align: "left",
          render: (c) => <AdminLink model={c.vendor}>{c.vendor.name}</AdminLink>,
        },
        {
          id: "period_begin",
          label: "Opens",
          align: "center",
          render: (c) => dayjs(c.periodBegin).format("l"),
        },
        {
          id: "period_end",
          label: "Closes",
          align: "center",
          render: (c) => dayjs(c.periodEnd).format("l"),
        },
      ]}
    />
  );
}
