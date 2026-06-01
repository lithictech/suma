import createRelativeUrl from "../shared/createRelativeUrl";
import AdminLink from "./AdminLink";
import RelatedListRemote from "./RelatedListRemote";
import React from "react";

export default function EligibilityRequirementsRelatedList({ model, type }) {
  return (
    <RelatedListRemote
      title="Eligibility Requirements"
      collection={model.eligibilityRequirements}
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
