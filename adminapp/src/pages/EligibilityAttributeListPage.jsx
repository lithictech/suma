import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function EligibilityAttributeListPage() {
  return (
    <ResourceList
      resource="eligibility_attribute"
      apiList={api.getEligibilityAttributes}
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
          render: (c) => <AdminLink model={c}>{c.name}</AdminLink>,
        },
        {
          id: "parent",
          label: "Parent",
          align: "center",
          sortable: true,
          render: (c) =>
            c.parent && <AdminLink model={c.parent}>{c.parent.name}</AdminLink>,
        },
      ]}
    />
  );
}
