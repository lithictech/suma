import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function RegistrationLinkForm({
  isCreate,
  resource,
  setFieldFromInput,
  setField,
  clearField,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Registration Link" : "Update Registration Link"}
      subtitle="Users who sign up via a registration link become
      automatically verified members of an organization."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <AutocompleteSearch
          key="org"
          {...register("organization")}
          label="Organization"
          helperText="All members of the organization get the attribute."
          value={resource.organization?.label || ""}
          fullWidth
          disabled={!isCreate}
          search={api.searchOrganizations}
          style={{ flex: 1 }}
          onValueSelect={(org) => setField("organization", org)}
          onTextChange={() => clearField("organization")}
        />
        <TextField
          {...register("icalEvent")}
          label="ICal Event"
          name="description"
          value={resource.description}
          fullWidth
          helperText="What does it mean for a member or organization to have this role?"
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
