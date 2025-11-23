import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function AnonMemberContactListPage() {
  return (
    <ResourceList
      resource="member_contact"
      apiList={api.getAnonMemberContacts}
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
          id: "address",
          label: "Address",
          align: "left",
          sortable: true,
          render: (c) => c.formattedAddress,
        },
      ]}
    />
  );
}
