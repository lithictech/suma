import api from "../api";
import AdminLink from "../components/AdminLink";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import createRelativeUrl from "../shared/createRelativeUrl";
import React from "react";

export default function EligibilityAttributeDetailPage() {
  return (
    <ResourceDetail
      resource="eligibility_attribute"
      apiGet={api.getEligibilityAttribute}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Name", value: model.name },
        { label: "Description", value: model.description },
        model.parent && {
          label: "Parent",
          value: <AdminLink model={model.parent}>{model.parent.name}</AdminLink>,
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Children"
          rows={model.children}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink model={row}>{row.name}</AdminLink>,
          ]}
        />,
        <RelatedList
          title="Assignments"
          rows={model.assignments}
          addNewLabel="Add Assignment"
          addNewRole="eligibilityAssignment"
          addNewLink={createRelativeUrl(`/eligibility-assignment/new`, {
            attributeId: model.id,
            attributeLabel: model.label,
          })}
          headers={["Id", "Assignee"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="assignee" model={row.assignee}>
              {row.assigneeLabel}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Referenced Requirements"
          rows={model.referencedRequirements}
          headers={["Id", "Resource", "Expression"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="id" model={row}>
              {row.resourceLabel}
            </AdminLink>,
            row.expressionFormulaStr,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
