import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResourceEdit from "../components/ResourceEdit";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import { formatOrNull } from "../modules/dayConfig";
import { Stack, TextField } from "@mui/material";
import startCase from "lodash/startCase";
import React from "react";

export default function OffPlatformTransactionEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getOffPlatformTransaction}
      apiUpdate={api.updateOffPlatformTransaction}
      Form={Form}
    />
  );
}

function Form({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title={`Edit Off Platform ${startCase(resource.type)}`}
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack gap={2}>
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
          seconds={true}
          onChange={(v) => setField("transactedAt", formatOrNull(v))}
        />
        <TextField
          {...register("note")}
          label="Note"
          name="note"
          value={resource.note}
          type="text"
          variant="outlined"
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
      </Stack>
    </FormLayout>
  );
}
