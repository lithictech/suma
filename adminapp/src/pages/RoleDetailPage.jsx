import api from "../api";
import AdminLink from "../components/AdminLink";
import EligibilityAssignmentsRelatedList from "../components/EligibilityAssignmentsRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import createRelativeUrl from "../shared/createRelativeUrl";
import React from "react";

export default function RoleDetailPage() {
  return (
    <ResourceDetail
      resource="role"
      apiGet={api.getRole}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Name", value: model.name },
        { label: "Description", value: model.description },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Members"
          rows={model.members}
          headers={["Id", "Name", "Phone"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            row.name,
            row.formattedPhone,
          ]}
        />,
        <RelatedList
          title="Organizations"
          rows={model.organizations}
          headers={["Id", "Name"]}
          keyRowAttr="id"
          toCells={(row) => [<AdminLink key="id" model={row} />, row.name]}
        />,
        <EligibilityAssignmentsRelatedList model={model} type="role" />,
      ]}
    </ResourceDetail>
  );
}
