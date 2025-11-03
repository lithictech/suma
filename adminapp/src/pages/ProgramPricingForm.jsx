import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import FormLayout from "../components/FormLayout";
import { FormLabel, Stack } from "@mui/material";
import React from "react";

export default function ProgramPricingForm({
  isCreate,
  resource,
  setField,
  register,
  isBusy,
  onSubmit,
}) {
  return (
    <FormLayout
      title={isCreate ? "Create Program Pricing" : "Update Program Pricing"}
      subtitle="Program pricing controls how much members pay for using a vendor service."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <FormLabel>Program Pricing</FormLabel>
        <AutocompleteSearch
          {...register("program")}
          label="Program"
          value={isCreate ? resource.program.label || "" : resource.program.name.en}
          fullWidth
          search={() => Promise.resolve({ data: { items: [] } })}
          required
          disabled
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("program", p)}
        />
        <AutocompleteSearch
          {...register("vendorService")}
          label="Vendor Service"
          value={
            isCreate
              ? resource.vendorService.label || ""
              : resource.vendorService.internalName
          }
          fullWidth
          search={api.searchVendorServices}
          required
          disabled={!isCreate}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("vendorService", p)}
        />
        <AutocompleteSearch
          {...register("vendorServiceRate")}
          label="Service Rate"
          value={
            isCreate
              ? resource.vendorServiceRate.label || ""
              : resource.vendorServiceRate.internalName
          }
          fullWidth
          search={api.searchVendorServiceRates}
          required
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("vendorServiceRate", p)}
        />
      </Stack>
    </FormLayout>
  );
}
