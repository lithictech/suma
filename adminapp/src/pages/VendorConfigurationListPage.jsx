import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function VendorConfigurationListPage() {
  return (
    <ResourceList
      resource="vendor_configuration"
      apiList={api.getVendorConfigurations}
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
          id: "auth_to_vendor_key",
          label: "Auth To Vendor",
          align: "center",
          render: (c) => c.authToVendorKey,
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
