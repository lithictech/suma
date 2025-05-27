import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjsOrNull } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
import React from "react";

export default function MarketingSmsDispatchListPage() {
  return (
    <ResourceList
      resource="marketing_sms_dispatch"
      apiList={api.getMarketingSmsDispatches}
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
          id: "campaign",
          label: "Campaign",
          align: "left",
          render: (c) => (
            <AdminLink model={c.smsCampaign}>{c.smsCampaign.label}</AdminLink>
          ),
        },
        {
          id: "member",
          label: "Member",
          align: "left",
          render: (c) => <AdminLink model={c.member}>{c.member.name}</AdminLink>,
        },
        {
          id: "status",
          label: "Status",
          align: "center",
          render: (c) => c.status,
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
