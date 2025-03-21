import api from "../api";
import AdminLink from "../components/AdminLink";
import ProgramEnrollmentRelatedList from "../components/ProgramEnrollmentRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import createRelativeUrl from "../shared/createRelativeUrl";
import React from "react";

export default function OrganizationDetailPage() {
  return (
    <ResourceDetail
      resource="organization"
      apiGet={api.getOrganization}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Name", value: model.name },
      ]}
    >
      {(model) => (
        <>
          <ProgramEnrollmentRelatedList
            model={model}
            resource="organization"
            enrollments={model.programEnrollments}
          />
          <RelatedList
            title={`Memberships (${model.memberships.length})`}
            rows={model.memberships}
            addNewLabel="Create another membership"
            addNewLink={createRelativeUrl(`/membership/new`, {
              organizationId: model.id,
              organizationLabel: `(${model.id}) ${model.name || "-"}`,
            })}
            addNewRole="organizationMembership"
            headers={["Id", "Member", "Created At"]}
            keyRowAttr="id"
            toCells={(row) => [
              <AdminLink model={row} />,
              <AdminLink key="member" model={row.member}>
                {row.member.name}
              </AdminLink>,
              formatDate(row.createdAt),
            ]}
          />
        </>
      )}
    </ResourceDetail>
  );
}
