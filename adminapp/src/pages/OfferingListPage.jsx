import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OfferingListPage() {
  return (
    <ResourceList
      apiList={api.getCommerceOfferings}
      toCreate="/offering/new"
      title="Offerings"
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
          id: "description",
          label: "Description",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.description.en}</AdminLink>,
        },
        {
          id: "orders",
          label: "Order Count",
          align: "center",
          render: (c) => c.orderCount,
        },
        {
          id: "product_amount",
          label: "Product Count",
          align: "center",
          render: (c) => c.productCount,
        },
        {
          id: "opens_at",
          label: "Opens",
          align: "center",
          render: (c) => dayjs(c.opensAt).format("l"),
        },
        {
          id: "closes_at",
          label: "Closes",
          align: "center",
          render: (c) => dayjs(c.closesAt).format("l"),
        },
      ]}
    />
  );
}
