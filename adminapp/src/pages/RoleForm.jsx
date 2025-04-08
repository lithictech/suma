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
      subtitle="Most roles are system controlled.
      You can also create roles that can be used to control resource access,
      like through Program Enrollments."
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
      </Stack>
    </FormLayout>
  );
}
