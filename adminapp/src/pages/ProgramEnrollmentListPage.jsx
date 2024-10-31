import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjsOrNull } from "../modules/dayConfig";
import React from "react";

export default function ProgramEnrollmentListPage() {
  return (
    <ResourceList
      resource="program_enrollment"
      apiList={api.getProgramEnrollments}
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
          id: "program",
          label: "Program",
          align: "left",
          render: (c) => <AdminLink model={c.program}>{c.program.name.en}</AdminLink>,
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member?.name}</AdminLink>,
          hideEmpty: true,
        },
        {
          id: "organization",
          label: "Organization",
          align: "left",
          render: (c) => (
            <AdminLink model={c.organization}>{c.organization?.name}</AdminLink>
          ),
          hideEmpty: true,
        },
        {
          id: "approved_at",
          label: "Approved",
          align: "left",
          render: (c) => dayjsOrNull(c.approvedAt)?.format("l"),
          hideEmpty: true,
        },
        {
          id: "unenrolled_at",
          label: "Unenrolled",
          align: "center",
          render: (c) => dayjsOrNull(c.unenrolledAt)?.format("l"),
          hideEmpty: true,
        },
      ]}
    />
  );
}
