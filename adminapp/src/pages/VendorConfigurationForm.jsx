import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import { FormControlLabel, FormLabel, Stack, Switch, TextField } from "@mui/material";
import React from "react";

export default function VendorConfigurationForm({
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
        isCreate
          ? "Create an External Account Vendor Configuration"
          : "Updaten External Account Vendor Configuration"
      }
      subtitle="External Account Vendor Configurations are available on
      the 'External Accounts' area of the application,
      and members who can access them via programs, can set up External Accounts
      using this Configuration."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("appInstallLink")}
          label="App Install Link"
          name="appInstallLink"
          value={resource.appInstallLink}
          fullWidth
          onChange={setFieldFromInput}
        />
        <FormControlLabel
          control={<Switch />}
          label="Enabled"
          name="enabled"
          checked={resource.enabled}
          onChange={setFieldFromInput}
        />
        <FormLabel>Setup Instructions</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("instructions")}
            label=""
            fullWidth
            value={resource.instructions}
            multiline
            required
            onChange={(v) => setField("instructions", v)}
          />
        </ResponsiveStack>
        <FormLabel>Linked Success Instructions</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("linkedSuccessInstructions")}
            label=""
            fullWidth
            value={resource.linkedSuccessInstructions}
            multiline
            required
            onChange={(v) => setField("linkedSuccessInstructions", v)}
          />
        </ResponsiveStack>
      </Stack>
    </FormLayout>
  );
}
