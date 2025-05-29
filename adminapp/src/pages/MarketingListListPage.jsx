import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import React from "react";

export default function MarketingListListPage() {
  return (
    <ResourceList
      resource="marketing_list"
      apiList={api.getMarketingLists}
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
          id: "label",
          label: "Label",
          sortable: true,
          align: "left",
          render: (c) => <AdminLink model={c}>{c.label}</AdminLink>,
        },
      ]}
    />
  );
}
