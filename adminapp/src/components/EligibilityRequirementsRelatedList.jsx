import createRelativeUrl from "../shared/createRelativeUrl";
import AdminLink from "./AdminLink";
import RelatedList from "./RelatedList";
import React from "react";

export default function EligibilityRequirementsRelatedList({ model, type }) {
  return (
    <RelatedList
      title="Eligibility Requirements"
      rows={model.eligibilityRequirements}
      addNewLabel="Add requirement"
      addNewLink={createRelativeUrl(`/eligibility-requirement/new`, {
        resourceId: model.id,
        resourceType: type,
        resourceLabel: model.label,
      })}
      addNewRole="eligibilityRequirement"
      headers={["Id", "Formula"]}
      keyRowAttr="id"
      toCells={(row) => [
        <AdminLink key="id" model={row} />,
        <AdminLink key="id" model={row}>
          {row.expressionFormulaStr || "<empty>"}
        </AdminLink>,
      ]}
    />
  );
}
