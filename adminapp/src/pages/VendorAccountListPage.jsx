import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function VendorAccountListPage() {
  return (
    <ResourceList
      resource="vendor_account"
      apiList={api.getVendorAccounts}
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
            <AdminLink model={c.configuration.vendor}>
              {c.configuration.vendor.name || <Unavailable />}
            </AdminLink>
          ),
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
