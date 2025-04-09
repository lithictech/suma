import FormLayout from "../components/FormLayout";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function AnonMemberContactForm({
  isCreate,
  resource,
  setFieldFromInput,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={
        isCreate
          ? "Create an Anonymous Member Contact"
          : "Update an Anonymous Member Contact"
      }
      subtitle="Anonymous member contacts are automatically created by the Private/External Account system.
      You can modify the phone or email of a member's Anonymous Member Contact and delete their Vendor Account
      to reset their account and create a new External Account for the vendor."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("email")}
          fullWidth
          value={resource.email}
          label="Email"
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
