import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import React from "react";

export default function EligibilityAssignmentDetailPage() {
  return (
    <ResourceDetail
      resource="eligibility_assignment"
      apiGet={api.getEligibilityAssignment}
      apiDelete={api.destroyEligibilityAssignment}
      canEdit
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        {
          label: "Attribute",
          value: <AdminLink model={model.attribute}>{model.attribute.label}</AdminLink>,
        },
        {
          label: "Assignee",
          value: (
            <AdminLink model={model.assignee}>
              {model.assigneeLabel} ({model.assigneeType})
            </AdminLink>
          ),
        },
      ]}
    />
  );
}
