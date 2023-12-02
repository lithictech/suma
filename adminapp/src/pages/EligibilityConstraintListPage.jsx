import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import Unavailable from "../components/Unavailable";
import { dayjs } from "../modules/dayConfig";
import React from "react";

export default function EligibilityConstraintListPage() {
  return (
    <ResourceList
      apiList={api.getEligibilityConstraints}
      toCreate="/constraint/new"
      title="Eligibility Constraints"
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
          render: (c) => <AdminLink model={c}>{c.name || <Unavailable />}</AdminLink>,
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
