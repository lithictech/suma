import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OrderListPage() {
  return (
    <ResourceList
      resource="order"
      apiList={api.getCommerceOrders}
      canSearch={false}
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member.name}</AdminLink>,
        },
        {
          id: "items",
          label: "Items",
          align: "left",
          render: (c) => c.totalItemCount,
        },
        {
          id: "status",
          label: "Status",
          align: "left",
          render: (c) => c.statusLabel,
        },
      ]}
    />
  );
}
