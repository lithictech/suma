import api from "../api";
import AdminLink from "../components/AdminLink";
import BoolCheckmark from "../components/BoolCheckmark";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import detailPageImageProperties from "../components/detailPageImageProperties";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import React from "react";

export default function EligibilityAssignmentDetailPage() {
  return (
    <ResourceDetail
      resource="eligibility_assignment"
      apiGet={api.getEligibilityAssignment}
      apiDelete={api.destroyEligibilityAssignment}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        model.createdBy && {
          label: "Created By",
          value: <AdminLink model={model.createdBy}>{model.createdBy.name}</AdminLink>,
        },
        {
          label: "Attribute",
          value: <AdminLink model={model.attribute}>{model.attribute.fqn}</AdminLink>,
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
