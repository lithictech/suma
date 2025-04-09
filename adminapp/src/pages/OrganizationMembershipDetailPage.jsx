import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
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
        model.verifiedOrganization && {
          label: "Verified Organization",
          value: (
            <AdminLink key="org" model={model.verifiedOrganization}>
              {model.verifiedOrganization?.name}
            </AdminLink>
          ),
        },
        model.unverifiedOrganizationName && {
          label: "Unverified Organization",
          value: model.unverifiedOrganizationName,
        },
        model.formerOrganization && {
          label: "Former Organization",
          value: (
            <AdminLink key="org" model={model.formerOrganization}>
              {model.formerOrganization?.name} (removed{" "}
              {formatDate(model.formerlyInOrganizationAt)})
            </AdminLink>
          ),
        },
      ]}
    />
  );
}
