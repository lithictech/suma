import api from "../api";
import AdminLink from "../components/AdminLink";
import ResourceList from "../components/ResourceList";
import { dayjsOrNull } from "../modules/dayConfig";
import MarketingSmsCampaignCreatePage from "./MarketingSmsCampaignCreatePage";
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
          id: "program",
          label: "Program",
          align: "left",
          render: (c) => <AdminLink model={c.program}>{c.program.name.en}</AdminLink>,
        },
        {
          id: "enrollee",
          label: "Enrollee",
          align: "left",
          render: (c) => <AdminLink model={c.enrollee}>{c.enrollee?.name}</AdminLink>,
          hideEmpty: true,
        },
        {
          id: "enrollee_type",
          label: "Enrollee Type",
          align: "left",
          render: (c) => c.enrolleeType,
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
