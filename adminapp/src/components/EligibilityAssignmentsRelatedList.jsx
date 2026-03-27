import createRelativeUrl from "../shared/createRelativeUrl";
import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function EligibilityAssignmentsRelatedList({ model, type }) {
  return (
    <RelatedList
      title="Eligibility Assignments"
      rows={model.eligibilityAssignments}
      addNewLabel="Assign attribute"
      addNewLink={createRelativeUrl(`/eligibility-assignment/new`, {
        assigneeId: model.id,
        assigneeType: type,
        assigneeLabel: model.label,
      })}
      addNewRole="eligibilityAssignment"
      headers={["Id", "Attribute"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        <AdminLink key="attr" model={row.attribute}>
          {row.attribute.label}
        </AdminLink>,
      ]}
    />
  );
}
