import api from "../api";
import AdminLink from "../components/AdminLink";
import Link from "../components/Link";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { Button } from "@mui/material";
import React from "react";

export default function MarketingSmsCampaignDetailPage() {
  return (
    <ResourceDetail
      resource="marketing_sms_campaign"
      apiGet={api.getMarketingSmsCampaign}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Label", value: model.label },
        { label: "Created At", value: dayjs(model.createdAt) },
        {
          label: "Created By",
          value: <AdminLink model={model.createdBy}>{model.createdBy?.name}</AdminLink>,
        },
        { label: "Sent At", value: formatDate(model.sentAt) },
        { label: "English Body", value: model.body.en },
        {
          label: "English Payload",
          value: `${model.preview.enPayload.characters} characters, ${model.preview.enPayload.segments} segments, $${model.preview.enPayload.cost} per SMS`,
        },
        { label: "Spanish Body", value: model.body.es },
        {
          label: "Spanish Payload",
          value: `${model.preview.esPayload.characters} characters, ${model.preview.esPayload.segments} segments, $${model.preview.esPayload.cost} per SMS`,
        },
      ]}
    >
      {(model) => [
        <Button
          href={`/marketing-sms-campaign/${model.id}/send`}
          variant="contained"
          component={Link}
        >
          Review and {model.sentAt ? "Re-Send" : "Send"}
        </Button>,
        <RelatedList
          title="Lists"
          rows={model.lists}
          keyRowAttr="id"
          headers={["Id", "Label"]}
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="label" model={row}>
              {row.label}
            </AdminLink>,
          ]}
        />,
        <RelatedList
          title="Dispatches"
          rows={model.smsDispatches}
          keyRowAttr="id"
          headers={["Id", "Member", "Status", "Message ID", "Error"]}
          toCells={(row) => [
            <AdminLink key="id" model={row} />,
            <AdminLink key="member" model={row.member}>
              {row.member.name}
            </AdminLink>,
            row.status,
            row.transportMessageId,
            row.lastError,
          ]}
        />,
      ]}
    </ResourceDetail>
  );
}
