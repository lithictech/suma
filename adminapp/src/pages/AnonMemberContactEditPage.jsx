import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import { Stack, TextField, Typography } from "@mui/material";
import React from "react";

export default function AnonMemberContactEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getAnonMemberContact}
      apiUpdate={api.updateAnonMemberContact}
      Form={EditForm}
    />
  );
}

function EditForm({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Update an Anonymous Member Contact"
      subtitle="Anonymous member contacts are automatically created by the Private/External Account system.
      You can modify the phone or email of a member's Anonymous Member Contact and delete their Vendor Account
      to reset their account and create a new External Account for the vendor."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        {resource.email && (
          <TextField
            {...register("email")}
            fullWidth
            value={resource.email}
            label="Email"
            onChange={setFieldFromInput}
          />
        )}
        {resource.phone && (
          <TextField
            {...register("phone")}
            fullWidth
            value={resource.phone}
            label="Phone"
            helperText="WARNING: Modifying the phone number does NOT provision it in Signalwire.
            Only set this number to an existing Signalwire number.
            If you want to provision a new phone number,
            delete the Member Contact and create a new one for this member."
            onChange={setFieldFromInput}
          />
        )}
      </Stack>
    </FormLayout>
  );
}
