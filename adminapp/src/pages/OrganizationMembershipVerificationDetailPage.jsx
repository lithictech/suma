import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import OrganizationMembership from "../components/OrganizationMembership";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { Stack } from "@mui/material";
import React from "react";

export default function OrganizationMembershipVerificationDetailPage() {
  function toOutreachMessage(convo) {
    if (!convo) {
      return "";
    }
    if (convo.initialDraft) {
      return "Initial draft";
    }
    const by = convo.waitingOnAdmin ? "Admin" : "Member";
    return `By ${by} at ${formatDate(convo.lastUpdatedAt)}`;
  }

  return (
    <ResourceDetail
      resource="organization_membership_verification"
      apiGet={api.getOrganizationMembershipVerification}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Status", value: model.status },
        {
          label: "Member",
          value: (
            <AdminLink model={model.membership.member}>
              {model.membership.member.name}
            </AdminLink>
          ),
        },
        {
          label: "Membership",
          children: (
            <Stack direction="row" gap={1}>
              <AdminLink model={model.membership} />
              <OrganizationMembership membership={model.membership} detailed />
            </Stack>
          ),
        },
        {
          label: "Owner",
          value: <AdminLink model={model.owner}>{model.owner?.name}</AdminLink>,
        },
        {
          label: "Front Partner Outreach Url",
          value: model.frontPartnerConversationStatus?.webUrl,
        },
        {
          label: "Front Partner Outreach Last Message",
          value: toOutreachMessage(model.frontPartnerConversationStatus),
        },
        {
          label: "Front Member Outreach Url",
          value: model.frontMemberConversationStatus?.webUrl,
        },
        {
          label: "Front Member Outreach Last Message",
          value: toOutreachMessage(model.frontMemberConversationStatus),
        },
      ]}
    >
      {(model) => [
        <RelatedList
          title="Notes"
          rows={model.notes}
          headers={["Id", "Note", "At", "Created by"]}
          keyRowAttr="id"
          toCells={(row) => [
            row.id,
            <div dangerouslySetInnerHTML={{ __html: row.contentHtml }} />,
            formatDate(row.createdAt),
            <AdminLink key="member" model={row.creator}>
              {row.creator.name}
            </AdminLink>,
          ]}
        />,
        <AuditLogs auditLogs={model.auditLogs} />,
      ]}
    </ResourceDetail>
  );
}
