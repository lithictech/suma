import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import formatDate from "../modules/formatDate";
import React from "react";

export default function MarketingSmsCampaignListPage() {
  return (
    <ResourceList
      resource="marketing_sms_campaign"
      apiList={api.getMarketingSmsCampaigns}
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
          align: "left",
          render: (c) => <AdminLink model={c}>{c.label}</AdminLink>,
        },
        {
          id: "sent_at",
          label: "Sent At",
          align: "left",
          render: (c) => formatDate(c.sentAt),
        },
      ]}
    />
  );
}
