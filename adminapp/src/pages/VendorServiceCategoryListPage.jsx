import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function VendorServiceCategoryListPage() {
  return (
    <ResourceList
      resource="vendor_service_category"
      apiList={api.getVendorServiceCategories}
      canCreate
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "slug",
          label: "Slug",
          align: "center",
          render: (c) => <AdminLink model={c}>{c.slug}</AdminLink>,
        },
        {
          id: "parent",
          label: "Parent",
          align: "center",
          render: (c) =>
            c.parent && <AdminLink model={c.parent}>{c.parent.slug}</AdminLink>,
        },
      ]}
    />
  );
}
