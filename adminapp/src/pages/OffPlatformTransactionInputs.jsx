import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import { TextField } from "@mui/material";
import React from "react";

export default function OffPlatformTransactionInputs({
  register,
  resource,
  setField,
  setFieldFromInput,
}) {
  return (
    <>
      <ResponsiveStack>
        <CurrencyTextField
          {...register("amount")}
          label="Amount"
          helperText="How much was transacted?"
          money={resource.amount}
          sx={{ width: { xs: "100%", sm: "auto" } }}
          required
          onMoneyChange={(f) => setField("amount", f)}
        />
        <SafeDateTimePicker
          label="Transacted At"
          value={resource.transactedAt}
          required
          onChange={(v) => setField("transactedAt", formatOrNull(v))}
        />
      </ResponsiveStack>
      <TextField
        {...register("note")}
        label="Note"
        name="note"
        value={resource.note}
        type="text"
        variant="outlined"
        required
        fullWidth
        onChange={setFieldFromInput}
      />
      <TextField
        {...register("checkOrTransactionNumber")}
        label="Check/Transaction Number"
        name="checkOrTransactionNumber"
        value={resource.checkOrTransactionNumber || ""}
        type="text"
        variant="outlined"
        fullWidth
        onChange={setFieldFromInput}
      />
      <AutocompleteSearch
        {...register("vendor")}
        label="Vendor"
        helperText="Is this transaction associated with a vendor, like the invoice sender?"
        value={resource.vendor?.name || ""}
        search={api.searchVendors}
        searchEmpty
        onValueSelect={(v) => setField("vendor", v)}
      />
      <AutocompleteSearch
        {...register("organization")}
        label="Organization"
        helperText="Is this transaction associated with an organization, like a funder?"
        value={resource.organization?.name || ""}
        search={api.searchOrganizations}
        searchEmpty
        onValueSelect={(v) => setField("organization", v)}
      />
    </>
  );
}
