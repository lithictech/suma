import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function EligibilityAssignmentListPage() {
  return (
    <ResourceList
      resource="eligibility_assignment"
      apiList={api.getEligibilityAssignments}
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
          id: "attribute",
          label: "Attribute",
          align: "left",
          render: (c) => <AdminLink model={c.attribute}>{c.attribute.name}</AdminLink>,
        },
        {
          id: "assignee",
          label: "Assignee",
          align: "left",
          render: (c) => <AdminLink model={c.assignee}>{c.assigneeLabel}</AdminLink>,
        },
        {
          id: "assigneeType",
          label: "Type",
          align: "left",
          render: (c) => c.assigneeType,
        },
      ]}
    />
  );
}
