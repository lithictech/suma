import api from "../api";
import AdminLink from "../components/AdminLink";
import EligibilityAssignmentsRelatedList from "../components/EligibilityAssignmentsRelatedList";
import RelatedListRemote from "../components/RelatedListRemote";
import ResourceDetail from "../components/ResourceDetail";
import resourceDetailCommonFields from "../components/resourceDetailCommonFields";
import React from "react";

export default function RoleDetailPage() {
  return (
    <ResourceDetail
      resource="role"
      apiGet={api.getRole}
      properties={(model) => [
        ...resourceDetailCommonFields(model),
        { label: "Name", value: model.name },
        { label: "Description", value: model.description },
      ]}
    >
      {(model) => [
        <RelatedListRemote
          title="Members"
          collection={model.members}
          headers={["Id", "Name", "Phone"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            row.name,
            row.formattedPhone,
          ]}
        />,
        <RelatedListRemote
          title="Organizations"
          collection={model.organizations}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [<AdminLink key="id" model={row} />, row.name]}
        />,
        <EligibilityAssignmentsRelatedList model={model} type="role" />,
      ]}
    </ResourceDetail>
  );
}
