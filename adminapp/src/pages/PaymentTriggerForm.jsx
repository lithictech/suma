import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import { dayjsOrNull, formatOrNull } from "../modules/dayConfig";
import { intToMoney } from "../shared/money";
import { TextField, Stack, FormHelperText } from "@mui/material";
import { DateTimePicker } from "@mui/x-date-pickers";
import React from "react";

export default function PaymentTriggerForm({
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
      title={isCreate ? "Create a Payment Trigger" : "Update Payment Trigger"}
      subtitle="Payment triggers create (or plan the creation of) a subsidy to a subledger when money is added (or will be added) to the cash ledger."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <Stack spacing={2}>
        <TextField
          {...register("label")}
          label="Label"
          name="label"
          value={resource.label}
          variant="outlined"
          fullWidth
          required
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <DateTimePicker
            label="Active starting"
            value={dayjsOrNull(resource.activeDuringBegin)}
            closeOnSelect
            onChange={(v) => setField("activeDuringBegin", formatOrNull(v))}
            sx={{ width: "100%" }}
          />
          <DateTimePicker
            label="Active ending"
            value={dayjsOrNull(resource.activeDuringEnd)}
            onChange={(v) => setField("activeDuringEnd", formatOrNull(v))}
            closeOnSelect
            sx={{ width: "100%" }}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <TextField
            {...register("matchMultiplier")}
            label="Match Multiplier"
            helperText="For each dollar put in, how much do we give the member?"
            name="matchMultiplier"
            value={resource.matchMultiplier}
            type="number"
            variant="outlined"
            fullWidth
            required
            style={{ flex: 1 }}
            onChange={setFieldFromInput}
          />
          <CurrencyTextField
            {...register("maximumCumulativeSubsidyCents")}
            label="Max Subsidy"
            helperText="What is the total amount that can be given to a member from this trigger?"
            money={intToMoney(resource.maximumCumulativeSubsidyCents)}
            required
            style={{ flex: 1 }}
            onMoneyChange={(v) => setField("maximumCumulativeSubsidyCents", v.cents)}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <MultiLingualText
            {...register("memo")}
            label="Memo"
            fullWidth
            value={resource.memo}
            required
            onChange={(v) => setField("memo", v)}
          />
        </ResponsiveStack>
        <FormHelperText>
          This memo is used for all triggered subsidy transactions.
        </FormHelperText>
        <AutocompleteSearch
          {...register("originatingLedger")}
          label="Originating Ledger"
          helperText="Where is the money coming from?"
          value={resource.originatingLedger?.adminLabel || ""}
          required
          search={api.searchLedgers}
          style={{ flex: 1 }}
          searchEmpty
          onValueSelect={(v) => setField("originatingLedger", v)}
        />
        <TextField
          {...register("receivingLedgerName")}
          label="Receiving Ledger"
          helperText="The name of the ledger created for the member. Not shown to members."
          name="receivingLedgerName"
          value={resource.receivingLedgerName}
          variant="outlined"
          fullWidth
          required
          onChange={setFieldFromInput}
        />
        <ResponsiveStack>
          <MultiLingualText
            {...register("receivingLedgerContributionText")}
            label="Contribution Text"
            fullWidth
            value={resource.receivingLedgerContributionText}
            required
            onChange={(v) => setField("receivingLedgerContributionText", v)}
          />
        </ResponsiveStack>
        <FormHelperText>
          The ledger 'name' shown to the member. Explain where this subledger money is
          used for.
        </FormHelperText>
      </Stack>
    </FormLayout>
  );
}
