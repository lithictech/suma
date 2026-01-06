import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import StateMachineStateSelect from "../components/StateMachineStateSelect";
import { Stack, TextField } from "@mui/material";
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

function VerificationForm({
  resource,
  setFieldFromInput,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
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
        <StateMachineStateSelect
          {...register("status")}
          stateMachineName="organization_membership_verification_status"
          name="status"
          value={resource.status}
          variant="outlined"
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("partnerOutreachFrontConversationId")}
          label="Partner Outreach Front Conversation Id"
          name="partnerOutreachFrontConversationId"
          value={resource.partnerOutreachFrontConversationId || ""}
          variant="outlined"
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("memberOutreachFrontConversationId")}
          label="Member Outreach Front Conversation Id"
          name="memberOutreachFrontConversationId"
          value={resource.memberOutreachFrontConversationId || ""}
          variant="outlined"
          onChange={setFieldFromInput}
        />
        <AutocompleteSearch
          {...register("organizationName")}
          label="Organization"
          value={resource.organizationName}
          fullWidth
          required
          disabled={!resource.organizationNameEditable}
          search={api.searchOrganizations}
          style={{ flex: 1 }}
          onValueSelect={(org) => setField("organizationName", org.name)}
        />
      </Stack>
    </FormLayout>
  );
}
