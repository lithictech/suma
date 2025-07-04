import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Unavailable from "../components/Unavailable";
import formatDate from "../modules/formatDate";
import React from "react";

export default function MemberListPage() {
  return (
    <ResourceList
      resource="member"
      apiList={api.getMembers}
      canSearch
      csvDownloadUrl="/adminapi/v1/members"
      columns={[
        {
          id: "id",
          label: "ID",
          align: "center",
          sortable: true,
          render: (c) => <AdminLink model={c} />,
        },
        {
          id: "phone",
          label: "Phone Number",
          align: "center",
          sortable: true,
          render: (c) => c.formattedPhone,
        },
        {
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name || <Unavailable />}</AdminLink>,
        },
        {
          id: "created_at",
          label: "Registered",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.createdAt),
        },
        {
          id: "onboarding_verified_at",
          label: "Verified",
          align: "left",
          sortable: true,
          render: (c) => formatDate(c.onboardingVerifiedAt),
        },
      ]}
    />
  );
}
