import api from "../api";
import AutocompleteSearch from "../components/AutocompleteSearch";
import CurrencyTextField from "../components/CurrencyTextField";
import FormLayout from "../components/FormLayout";
import MultiLingualText from "../components/MultiLingualText";
import ResponsiveStack from "../components/ResponsiveStack";
import SafeDateTimePicker from "../components/SafeDateTimePicker";
import config from "../config";
import { formatOrNull } from "../modules/dayConfig";
import { intToMoney } from "../shared/money";
import { TextField, Stack, FormHelperText } from "@mui/material";
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
  // Get this logic from payment_trigger.rb
  function setPayerFraction(v) {
    setField("matchMultiplier", 1.0 / v - 1);
  }
  const payerFraction = 1.0 / (resource.matchMultiplier + 1);
  function setMatchFraction(v) {
    setPayerFraction(1 - v);
  }
  const matchFraction = 1 - payerFraction;

  // UI-specific massage.
  let payerPercent = Math.round(payerFraction * 100);
  let matchPercent = Math.round(matchFraction * 100);
  if (!resource.matchMultiplier) {
    payerPercent = "";
    matchPercent = "";
  }
  const setPayerPercent = (e) => {
    setPayerFraction(Number(e.target.value) / 100.0);
  };
  const setMatchPercent = (e) => {
    setMatchFraction(Number(e.target.value) / 100.0);
  };

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
          <SafeDateTimePicker
            label="Active starting"
            value={resource.activeDuringBegin}
            onChange={(v) => setField("activeDuringBegin", formatOrNull(v))}
          />
          <SafeDateTimePicker
            label="Active ending"
            value={resource.activeDuringEnd}
            onChange={(v) => setField("activeDuringEnd", formatOrNull(v))}
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
            required
            style={{ flex: 1 }}
            inputProps={{ step: 0.01 }}
            onChange={setFieldFromInput}
          />
          <TextField
            {...register("matchPercentage")}
            label="Match Percentage"
            helperText="For each dollar of cost, how much we we subsidize?"
            name="matchPercentage"
            value={matchPercent}
            type="number"
            variant="outlined"
            required
            style={{ flex: 1 }}
            onChange={setMatchPercent}
          />
          <TextField
            {...register("payerPercentage")}
            label="Payer Percentage"
            helperText="For each dollar of cost, how much does the member pay?"
            name="payerPercentage"
            value={payerPercent}
            type="number"
            variant="outlined"
            required
            style={{ flex: 1 }}
            onChange={setPayerPercent}
          />
        </ResponsiveStack>
        <ResponsiveStack>
          <CurrencyTextField
            {...register("maximumCumulativeSubsidyCents")}
            label="Max Subsidy"
            helperText="What is the total amount that can be given to a member from this trigger?"
            money={intToMoney(
              resource.maximumCumulativeSubsidyCents,
              config.defaultCurrency.code
            )}
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
          This Memo appears on all subsidy transactions between the originated and
          receiving ledgers specified below. Sometimes this is the same as the
          Contribution Text below, but more often it should be focused on the Originating
          Ledger. For example, a holiday meal subsidy could originate from the "Holiday
          Meal 2020" ledger, have a Memo of "Subsidy from local funders", and have a
          Contribution Text of "Food". To the user, this would appear as a transaction on
          their Food ledger; to the platform, it would track the subsidy came from a
          dedicated ledger.
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
          onValueSelect={(v) => setField("originatingLedger.id", v.id)}
        />
        <TextField
          {...register("receivingLedgerName")}
          label="Receiving Ledger"
          helperText="The internal name of the ledger created for the member. Not shown to members."
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
          The 'ledger name' shown to the member. This appears when viewing their
          transaction history for a specific ledger, or as a description along with the
          Memo specified above. See Memo helper text for more info.
        </FormHelperText>
      </Stack>
    </FormLayout>
  );
}
