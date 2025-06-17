import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditActivityList from "../components/AuditActivityList";
import {
  OrganizationMembershipRemovedIcon,
  OrganizationMembershipVerifiedIcon,
} from "../components/OrganizationMembership";
import ProgramEnrollmentRelatedList from "../components/ProgramEnrollmentRelatedList";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import createRelativeUrl from "../shared/createRelativeUrl";
import { Chip } from "@mui/material";
import React from "react";

export default function OrganizationDetailPage() {
  return (
    <ResourceDetail
      resource="organization"
      apiGet={api.getOrganization}
      canEdit
      properties={(model) => [
        { label: "ID", value: model.id },
        { label: "Created At", value: dayjs(model.createdAt) },
        { label: "Updated At", value: dayjs(model.updatedAt) },
        { label: "Name", value: model.name },
        { label: "Ordinal", value: model.ordinal },
        { label: "Verification Email", value: model.membershipVerificationEmail },
        {
          label: "Front Membership Verification Template",
          value: model.membershipVerificationFrontTemplateId,
        },
        {
          label: "Front Member Outreach Template (En)",
          value: model.membershipVerificationMemberOutreachTemplate?.en,
        },
        {
          label: "Front Member Outreach Template (Es)",
          value: model.membershipVerificationMemberOutreachTemplate?.es,
        },
        {
          label: "Roles",
          children: model.roles.map((role) => (
            <Chip key={role.id} label={role.label} sx={{ mr: 0.5 }} />
          )),
          hideEmpty: true,
        },
      ]}
    >
      {(model) => [
        <ProgramEnrollmentRelatedList
          model={model}
          resource="organization"
          enrollments={model.programEnrollments}
        />,
        <RelatedList
          title={
            <>
              <OrganizationMembershipVerifiedIcon />
              &nbsp;Memberships ({model.memberships.length}){" "}
            </>
          }
          rows={model.memberships}
          addNewLabel="Create another membership"
          addNewLink={createRelativeUrl(`/membership/new`, {
            organizationId: model.id,
            organizationLabel: `(${model.id}) ${model.name || "-"}`,
          })}
          addNewRole="organizationMembership"
          headers={["Id", "Member", "Added At"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink key="member" model={row.member}>
              {row.member.name}
            </AdminLink>,
            formatDate(row.createdAt),
          ]}
        />,
        <RelatedList
          title={
            <>
              <OrganizationMembershipRemovedIcon />
              &nbsp;Former Memberships ({model.formerMemberships.length})
            </>
          }
          rows={model.formerMemberships}
          headers={["Id", "Member", "Added At", "Removed At"]}
          keyRowAttr="id"
          toCells={(row) => [
            <AdminLink model={row} />,
            <AdminLink key="member" model={row.member}>
              {row.member.name}
            </AdminLink>,
            formatDate(row.createdAt),
            formatDate(row.formerlyInOrganizationAt),
          ]}
        />,
        <AuditActivityList activities={model.auditActivities} />,
      ]}
    </ResourceDetail>
  );
}
