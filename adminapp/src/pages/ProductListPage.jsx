import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function ProductListPage() {
  return (
    <ResourceList
      resource="product"
      apiList={api.getCommerceProducts}
      canCreate
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
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.createdAt),
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name.en}</AdminLink>,
        },
        {
          id: "vendor",
          label: "Vendor",
          align: "left",
          render: (c) => c.vendor.name,
        },
      ]}
    />
  );
}
