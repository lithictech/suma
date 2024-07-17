import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function VendibleGroupListPage() {
  return (
    <ResourceList
      apiList={api.getVendibleGroups}
      toCreate="/vendible-group/new"
      title="Vendible Groups"
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
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name.en}</AdminLink>,
        },
      ]}
    />
  );
}
