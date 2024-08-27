import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import React from "react";
import { formatPhoneNumber } from "react-phone-number-input";

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
          render: (c) => formatPhoneNumber("+" + c.phone),
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
          render: (c) => dayjs(c.createdAt).format("lll"),
        },
      ]}
    />
  );
}
