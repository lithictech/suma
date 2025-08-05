import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import config from "../config";
import { dayjs, formatOrNull } from "../modules/dayConfig";
import { FormControlLabel, Radio, RadioGroup, Stack, TextField } from "@mui/material";
import React from "react";

export default function OffPlatformTransactionCreatePage() {
  const empty = {
    type: "funding",
    amount: config.defaultZeroMoney,
    note: "",
    checkOrTransactionNumber: "",
    transactedAt: dayjs().toISOString(),
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createOffPlatformTransaction}
      Form={Form}
    />
  );
}

function Form({ resource, setField, setFieldFromInput, register, isBusy, onSubmit }) {
  return (
    <FormLayout
      title="Create an Off Platform Transaction"
      subtitle="Off Platform transactions represent the flow of funds into and out of the platform,
      which cannot be presented in other ways.
      For example, a check from a private funder providing a subsidy would be
      an Off Platform Funding Transaction. Paying an invoice, for example,
      would be an Off Platform Payout Transaction. We should try to represent these transactions
      with on-platform functions where possible; but in many cases, or in historical situations,
      it is not possible."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack gap={2}>
        <RadioGroup
          value={resource.type}
          row
          onChange={(e) => setField("type", e.target.value)}
        >
          <FormControlLabel value="funding" control={<Radio />} label="Funding" />
          <FormControlLabel value="payout" control={<Radio />} label="Payout" />
        </RadioGroup>
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
      </Stack>
    </FormLayout>
  );
}
