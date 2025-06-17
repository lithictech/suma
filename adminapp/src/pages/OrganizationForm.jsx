import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import RoleEditor from "../components/RoleEditor";
import { FormHelperText, FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

export default function OrganizationForm({
  isCreate,
  resource,
  setField,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create an Organization" : "Update Organization"}
      subtitle="Organizations are entities like Hacienda CDC or other suma
      partners that make a member eligible for our programs such as our
      affordable housing partners. Members signup or onboard with this
      organization choice."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("name")}
          label="Name"
          name="name"
          value={resource.name}
          type="name"
          variant="outlined"
          fullWidth
          required
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("ordinal")}
          label="Ordinal"
          helperText="The order in which organizations are displayed in the member onboarding flow, higher first."
          name="ordinal"
          value={resource.ordinal}
          type="number"
          variant="outlined"
          fullWidth
          required
          onChange={setFieldFromInput}
        />
        <RoleEditor roles={resource.roles} setRoles={(r) => setField("roles", r)} />
        <TextField
          {...register("membershipVerificationEmail")}
          label="Verification Email"
          helperText="Email to contact for questions about verifying membership."
          name="membershipVerificationEmail"
          value={resource.membershipVerificationEmail}
          type="membershipVerificationEmail"
          variant="outlined"
          fullWidth
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("membershipVerificationFrontTemplateId")}
          label="Front Membership Verification Template"
          helperText={
            <span>
              The Front template ID to use for messages{" "}
              <strong>sent to the verification email</strong>, asking about a member. You
              can get the ID from the URL of the template in Front. For example, in the
              URL 'https://app.frontapp.com/settings/tim:111/answers/333/edit', the ID
              would be '333'.
            </span>
          }
          name="membershipVerificationFrontTemplateId"
          value={resource.membershipVerificationFrontTemplateId}
          type="membershipVerificationFrontTemplateId"
          variant="outlined"
          fullWidth
          onChange={setFieldFromInput}
        />
        <FormLabel>Front Member Outreach Templates</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("membershipVerificationMemberOutreachTemplate")}
            label="Template Id"
            fullWidth
            value={resource.membershipVerificationMemberOutreachTemplate || {}}
            onChange={(v) => setField("membershipVerificationMemberOutreachTemplate", v)}
          />
        </ResponsiveStack>
        <FormHelperText>
          These are the Front templates used to generate the message{" "}
          <strong>sent to the member</strong>, localized according to their preferred
          language.
        </FormHelperText>
      </Stack>
    </FormLayout>
  );
}
