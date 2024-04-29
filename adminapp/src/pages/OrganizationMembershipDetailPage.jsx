import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OrganizationMembershipDetailPage() {
  return (
    <ResourceDetail
      apiGet={api.getOrganizationMembership}
      title={(model) => `Organization Membership ${model.id}`}
      toEdit={(model) => `/membership/${model.id}/edit`}
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
          label: "Verified Organization",
          value: (
            <AdminLink key="org" model={model.verifiedOrganization}>
              {model.verifiedOrganization?.name}
            </AdminLink>
          ),
        },
        {
          label: "Unverified Organization",
          value: model.unverifiedOrganizationName,
        },
      ]}
    />
  );
}
