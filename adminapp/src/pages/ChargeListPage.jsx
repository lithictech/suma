import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import React from "react";

export default function ChargeListPage() {
  return (
    <ResourceList
      resource="charge"
      apiList={api.getCharges}
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
          id: "created_at",
          label: "Created",
          align: "left",
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
        {
          id: "discounted_subtotal",
          label: "Discounted Subtotal",
          align: "left",
          render: (c) => <Money>{c.discountedSubtotal}</Money>,
        },
        {
          id: "undiscounted_subtotal",
          label: "Undiscounted Subtotal",
          align: "center",
          render: (c) => <Money>{c.undiscountedSubtotal}</Money>,
        },
      ]}
    />
  );
}
