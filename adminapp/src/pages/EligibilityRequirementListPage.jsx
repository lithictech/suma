import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function EligibilityRequirementListPage() {
  return (
    <ResourceList
      resource="eligibility_requirement"
      apiList={api.getEligibilityRequirements}
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
          id: "rez",
          label: "Resources",
          align: "left",
          render: (c) =>
            c.resources.length === 0
              ? "-"
              : AdminLink.Array(
                  c.resources,
                  (o) => <AdminLink model={o}>{o.label}</AdminLink>,
                  " , "
                ),
        },
      ]}
    />
  );
}
