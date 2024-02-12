import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function VendorConfigurationListPage() {
  return (
    <ResourceList
      apiList={api.getVendorConfigurations}
      title="Vendor Configurations"
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
          id: "vendor",
          label: "Vendor",
          align: "left",
          render: (c) => <AdminLink model={c.vendor}>{c.vendor.name}</AdminLink>,
        },
        {
          id: "uses_sms",
          label: "Uses SMS?",
          align: "center",
          render: (c) => <BoolCheckmark>{c.usesSms}</BoolCheckmark>,
        },
        {
          id: "uses_email",
          label: "Uses Email?",
          align: "center",
          render: (c) => <BoolCheckmark>{c.usesEmail}</BoolCheckmark>,
        },
        {
          id: "enabled",
          label: "Enabled?",
          align: "center",
          render: (c) => <BoolCheckmark>{c.enabled}</BoolCheckmark>,
        },
        {
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
      ]}
    />
  );
}
