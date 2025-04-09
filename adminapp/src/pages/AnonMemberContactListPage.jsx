import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function AnonMemberContactListPage() {
  return (
    <ResourceList
      resource="anon_member_contact"
      apiList={api.getAnonMemberContacts}
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
          id: "email",
          label: "Email",
          align: "left",
          sortable: true,
          render: (c) => c.email,
        },
        {
          id: "phone",
          label: "Phone",
          align: "left",
          sortable: true,
          render: (c) => c.phone,
        },
      ]}
    />
  );
}
