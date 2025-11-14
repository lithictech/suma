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
          ? "Create External Account Vendor Configuration"
          : "Update External Account Vendor Configuration"
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
        <FormLabel>Description</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("descriptionText")}
            label=""
            fullWidth
            value={resource.descriptionText}
            multiline
            required
            helperText="Shown to users on the Private Accounts list page."
            onChange={(v) => setField("descriptionText", v)}
          />
        </ResponsiveStack>
        <FormLabel>Help Text</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("helpText")}
            label=""
            fullWidth
            value={resource.helpText}
            multiline
            required
            helperText="Shown the 'help' modal on the list page."
            onChange={(v) => setField("helpText", v)}
          />
        </ResponsiveStack>
        <FormLabel>Terms</FormLabel>
        <ResponsiveStack>
          <MultiLingualText
            {...register("termsText")}
            label=""
            fullWidth
            value={resource.termsText}
            multiline
            required
            helperText="Terms of use users must agree to to link an account."
            onChange={(v) => setField("termsText", v)}
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
