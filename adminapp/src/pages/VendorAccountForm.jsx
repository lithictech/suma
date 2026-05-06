import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import { FormControlLabel, Stack, Switch, TextField, Typography } from "@mui/material";
import React from "react";

export default function VendorAccountForm({
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
      title={isCreate ? "Create External Account" : "Update External Account"}
      subtitle="External Vendor Accounts represent a member's account within an external vendor configuration."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Typography variant="subtitle1" color="error" sx={{ marginBottom: 4 }}>
        <strong>Be careful when changing these values. For technical use only.</strong>
      </Typography>
      <Stack spacing={2}>
        <TextField
          {...register("latestAccessCode")}
          label="Latest Access Code"
          name="latestAccessCode"
          value={resource.latestAccessCode}
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("latestAccessCodeMagicLink")}
          label="Latest Access Code Magic Link"
          name="latestAccessCodeMagicLink"
          value={resource.latestAccessCodeMagicLink}
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <SafeDateTimePicker
            label="Latest Access Code Set At"
            value={resource.latestAccessCodeSetAt}
            onChange={(v) => setField("latestAccessCodeSetAt", formatOrNull(v))}
            sx={{ width: { xs: "100%", sm: "50%" } }}
          />
          <SafeDateTimePicker
            label="Latest Access Code Requested At"
            value={resource.latestAccessCodeRequestedAt}
            onChange={(v) => setField("latestAccessCodeRequestedAt", formatOrNull(v))}
            sx={{ width: { xs: "100%", sm: "50%" } }}
          />
        </ResponsiveStack>
        <FormControlLabel
          control={<Switch />}
          label="Pending Closure"
          name="pendingClosure"
          checked={resource.pendingClosure}
          onChange={setFieldFromInput}
        />
      </Stack>
    </FormLayout>
  );
}
