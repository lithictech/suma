import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function RoleListPage() {
  return (
    <ResourceList
      resource="role"
      apiList={api.getRoles}
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
          id: "name",
          label: "Name",
          align: "left",
          sortable: true,
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "description",
          label: "Description",
          align: "left",
          sortable: false,
          render: (c) => c.description,
        },
      ]}
    />
  );
}
