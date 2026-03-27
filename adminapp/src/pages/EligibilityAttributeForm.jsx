import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function EligibilityAttributeForm({
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
      title={
        isCreate ? "Create an Eligibility Attribute" : "Update Eligibility Attribute"
      }
      subtitle="Eligibility attributes can be assigned to members/organizations/roles,
      and set as a requirement of programs and other resources,
      to control who has access to what.."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("name")}
          label="Name"
          name="name"
          value={resource.name}
          fullWidth
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("description")}
          label="Description"
          name="description"
          value={resource.description}
          fullWidth
          onChange={setFieldFromInput}
        />
        <AutocompleteSearch
          {...register("parent")}
          label="Parent"
          value={resource.parent?.name || ""}
          fullWidth
          search={api.searchEligibilityAttributes}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("parent", p)}
        />
      </Stack>
    </FormLayout>
  );
}
