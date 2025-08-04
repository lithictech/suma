import api from "../api";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import ResponsiveStack from "../components/ResponsiveStack";
import { dayjs } from "../modules/dayConfig";
import { FormControlLabel, Radio, RadioGroup, TextField } from "@mui/material";
import React from "react";

export default function OffPlatformTransactionEditPage() {
  const empty = {
    type: "funding",
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
        <RadioGroup value={resource.type} row onChange={(f) => setField("type", f)}>
          <FormControlLabel value="funding" control={<Radio />} label="Funding" />
          <FormControlLabel value="payout" control={<Radio />} label="Payout" />
        </RadioGroup>
      </ResponsiveStack>
    </FormLayout>
  );
}
