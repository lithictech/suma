import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function ProgramListPage() {
  return (
    <ResourceList
      resource="program"
      apiList={api.getPrograms}
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
          id: "name",
          label: "Name",
          align: "left",
          render: (c) => <AdminLink model={c}>{c.name.en}</AdminLink>,
        },
        {
          id: "app_link",
          label: "App Link",
          align: "left",
          render: (c) => c.appLink,
          hideEmpty: true,
        },
        {
          id: "period_begin",
          label: "Opens",
          align: "center",
          render: (c) => formatDate(c.periodBegin, { template: "l" }),
        },
        {
          id: "period_end",
          label: "Closes",
          align: "center",
          render: (c) => formatDate(c.periodEnd, { template: "l" }),
        },
      ]}
    />
  );
}
