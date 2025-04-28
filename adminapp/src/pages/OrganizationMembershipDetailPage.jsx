import api from "../api";
import AdminLink from "../components/AdminLink";
import OrganizationMembership from "../components/OrganizationMembership";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OrganizationMembershipDetailPage() {
  return (
    <ResourceDetail
      resource="organization_membership"
      apiGet={api.getOrganizationMembership}
      canEdit={(model) => !model.formerOrganization}
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        {
          label: "Member",
          value: (
            <AdminLink key="member" model={model.member}>
              {model.member.name}
            </AdminLink>
          ),
        },
        {
          label: "Organization",
          value: <OrganizationMembership membership={model} detailed />,
        },
      ]}
    />
  );
}
