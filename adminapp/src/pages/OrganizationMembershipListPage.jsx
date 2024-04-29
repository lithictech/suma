import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function OrganizationMembershipListPage() {
  return (
    <ResourceList
      apiList={api.getOrganizationMemberships}
      toCreate="/membership/new"
      title="Organization Memberships"
      canSearch
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member.name}</AdminLink>,
        },
        {
          id: "organization",
          label: "Organization",
          align: "left",
          render: (c) =>
            c.verifiedOrganization ? (
              <AdminLink model={c.organization}>{c.verifiedOrganization.name}</AdminLink>
            ) : (
              c.unverifiedOrganizationName
            ),
        },
        {
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
      ]}
    />
  );
}
