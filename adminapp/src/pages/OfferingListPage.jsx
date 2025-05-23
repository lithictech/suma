import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function OfferingListPage() {
  return (
    <ResourceList
      resource="offering"
      apiList={api.getCommerceOfferings}
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
          id: "period_begin",
          label: "Opens",
          align: "center",
          render: (c) => formatDate(c.periodBegin, { template: "l" }),
        },
        {
          id: "period_end",
          label: "Closes",
          align: "center",
          render: (c) => formatDate(c.periodEnd, { template: "l" }),
        },
      ]}
    />
  );
}
