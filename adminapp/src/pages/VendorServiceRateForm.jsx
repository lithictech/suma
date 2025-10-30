import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResponsiveStack from "../components/ResponsiveStack";
import { Stack, TextField } from "@mui/material";
import React from "react";

export default function VendorServiceRateForm({
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
      title={isCreate ? "Create a Vendor Service Rate" : "Update Vendor Service Rate"}
      subtitle="Vendor service rates control the pricing of vendor services.
      Note that rates are NOT specific to vendor services;
      the same rate can be reused across many services."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("internalName")}
          label="Internal Name"
          name="internalName"
          value={resource.internalName}
          required
          fullWidth
          helperText="Label for internal and administrative use."
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("externalName")}
          label="External Name"
          name="externalName"
          value={resource.externalName}
          required
          fullWidth
          helperText="Label that members see."
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <CurrencyTextField
            {...register("surcharge")}
            label="Surcharge"
            helperText="The surcharge on each use of the service. For example, this would be the unlock cost of a bike trip."
            money={resource.surcharge}
            required
            disabled={!isCreate}
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("surcharge", v)}
          />
          <CurrencyTextField
            {...register("unitAmount")}
            label="Unit Amount"
            helperText="The cost per 'unit' of the service. For example, this would be the cost per minute of a bike trip."
            money={resource.unitAmount}
            required
            disabled={!isCreate}
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("unitAmount", v)}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <TextField
            name="unitOffset"
            value={resource.unitOffset}
            type="number"
            label="Unit Offset"
            helperText="How many units are free for each service use? For example, this would be '30' if a member gets 30 minutes for free before being charged."
            fullWidth
            disabled={!isCreate}
            onChange={setFieldFromInput}
          />
          <TextField
            name="ordinal"
            value={resource.ordinal}
            type="number"
            label="Priority/Ordinal"
            helperText="When multiple rates for the same service are available to a member, the rate with the lowest ordinal will be used."
            fullWidth
            onChange={setFieldFromInput}
          />
        </ResponsiveStack>
        <AutocompleteSearch
          {...register("undiscountedRate")}
          label="Undiscounted Rate"
          value={resource.undiscountedRate?.name || ""}
          fullWidth
          search={api.searchVendorServiceRates}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(p) => setField("undiscountedRate", p)}
        />
      </Stack>
    </FormLayout>
  );
}
