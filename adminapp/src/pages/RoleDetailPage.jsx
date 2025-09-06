import api from "../api";
import AdminLink from "../components/AdminLink";
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
        <RelatedList
          title="Program Enrollments"
          rows={model.programEnrollments}
          headers={["Id", "Program"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="name" model={row.program}>
              {row.program.name.en}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Program Enrollment Exclusions"
          addNewLabel="Add Exclusion"
          addNewLink={createRelativeUrl(`/program-enrollment-exclusion/new`, {
            enrolleeId: model.id,
            enrolleeLabel: `(${model.id}) ${model.name}`,
            enrolleeType: "role",
          })}
          addNewRole="programEnrollmentExclusion"
          rows={model.programEnrollmentExclusions}
          headers={["Id", "Program"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="name" model={row.program}>
              {row.program.name.en}
            </AdminLink>,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
