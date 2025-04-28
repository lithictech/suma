import FormLayout from "../components/FormLayout";
import RoleEditor from "../components/RoleEditor";
import { Stack, TextField } from "@mui/material";
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
      </Stack>
    </FormLayout>
  );
}
