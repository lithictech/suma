import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import { FormLabel, Stack, TextField } from "@mui/material";
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
        <FormLabel>Intro:</FormLabel>
        <Stack spacing={2}>
          <MultiLingualText
            {...register("intro")}
            label="Intro"
            fullWidth
            value={resource.intro}
            required
            multiline
            onChange={(v) => setField("intro", v)}
          />
        </Stack>
        <FormLabel>Schedule:</FormLabel>
        <TextField
          {...register("icalEvent")}
          label="ICal Event"
          name="icalEvent"
          value={resource.icalEvent}
          fullWidth
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
