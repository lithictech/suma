import api from "../api";
import AdminLink from "../components/AdminLink";
import AuditLogs from "../components/AuditLogs";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import OrganizationMembership from "../components/OrganizationMembership";
import RelatedList from "../components/RelatedList";
import ResourceDetail from "../components/ResourceDetail";
import ResourceEdit from "../components/ResourceEdit";
import ResponsiveStack from "../components/ResponsiveStack";
import RoleEditor from "../components/RoleEditor";
import { dayjs } from "../modules/dayConfig";
import formatDate from "../modules/formatDate";
import { FormHelperText, FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function OrganizationMembershipVerificationEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOrganizationMembershipVerification}
      apiUpdate={api.updateOrganizationMembershipVerification}
      Form={VerificationForm}
    />
  );
}

function VerificationForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Update Verification Fields"
      subtitle="Edit the underlying Verification fields.
      You should generally never need to do this.
      You should use the workflow tools instead."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("status")}
          label="Status"
          name="status"
          value={resource.status}
          variant="outlined"
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("partnerOutreachFrontConversationId")}
          label="Partner Outreach Front Conversation Id"
          name="partnerOutreachFrontConversationId"
          value={resource.partnerOutreachFrontConversationId}
          variant="outlined"
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("memberOutreachFrontConversationId")}
          label="Member Outreach Front Conversation Id"
          name="memberOutreachFrontConversationId"
          value={resource.memberOutreachFrontConversationId}
          variant="outlined"
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
