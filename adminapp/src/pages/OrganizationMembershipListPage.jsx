import api from "../api";
import AdminLink from "../components/AdminLink";
import OrganizationMembership from "../components/OrganizationMembership";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function OrganizationMembershipListPage() {
  return (
    <ResourceList
      resource="organization_membership"
      apiList={api.getOrganizationMemberships}
      canCreate
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
          render: (c) => <OrganizationMembership membership={c} />,
        },
        {
          id: "verification",
          label: "Verification",
          align: "left",
          render: (c) => (
            <AdminLink model={c.verification}>{c.verification?.status}</AdminLink>
          ),
        },
        {
          id: "created_at",
          label: "Created",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.createdAt),
        },
      ]}
    />
  );
}
