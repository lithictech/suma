import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import OrganizationMembership from "../components/OrganizationMembership";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import membershipVerificationDuplicateChanceColor from "../modules/membershipVerificationDuplicateChanceColor";
import oneLineAddress from "../modules/oneLineAddress";
import useToggle from "../shared/react/useToggle";
import RefreshIcon from "@mui/icons-material/Refresh";
import LoadingButton from "@mui/lab/LoadingButton";
import { Stack } from "@mui/material";
import React from "react";

export default function OrganizationMembershipVerificationDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const rebuilding = useToggle();

  const handleRebuildDuplicates = React.useCallback(
    (model, setModel) => {
      rebuilding.turnOn();
      api
        .rebuildOrganizationMembershipVerificationDuplicates({ id: model.id })
        .then((r) => setModel(r.data))
        .catch(enqueueErrorSnackbar)
        .finally(rebuilding.turnOff);
    },
    [enqueueErrorSnackbar]
  );

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
          label: "Address",
          value: model.address && oneLineAddress(model.address),
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
      {(model, setModel) => [
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
        <RelatedList
          title="Duplicates"
          rows={model.duplicates}
          headers={["Id", "Name", "Phone", "Organization", "Reason"]}
          getKey={(r) => `${r.memberId}${r.reason}`}
          toCells={(row) => [
            <AdminLink key="id" to={row.memberAdminLink}>
              {row.memberId}
            </AdminLink>,
            <AdminLink key="name" to={row.memberAdminLink}>
              {row.memberName}
            </AdminLink>,
            row.memberPhone,
            row.organizationName,
            <span>
              {row.reason}
              <LoadingButton
                key="chance"
                loading={rebuilding.isOn}
                loadingPosition="start"
                sx={{ marginLeft: 1 }}
                startIcon={
                  <RefreshIcon
                    color={
                      membershipVerificationDuplicateChanceColor(row.chance) || "action"
                    }
                  />
                }
                onClick={() => handleRebuildDuplicates(model, setModel)}
              />
            </span>,
          ]}
        />,
        <AuditLogs auditLogs={model.auditLogs} />,
      ]}
    </ResourceDetail>
  );
}

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
