import FormLayout from "../components/FormLayout";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function RoleForm({
  isCreate,
  resource,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create a Role" : "Update Role"}
      subtitle="Some roles (admin, member) are system controlled,
      while others can be created by admins to provide a single way
      to control access for a group of members or organizations,
      by assigning them the role and then adding an Eligibility Assignment to the role."
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
          required
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("description")}
          label="Description"
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
