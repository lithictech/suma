import SimpleRadioGroup from "../SimpleRadioGroup";
import FrequencyDaily from "./FrequencyDaily";
import FrequencyMonthly from "./FrequencyMonthly";
import FrequencyWeekly from "./FrequencyWeekly";
import { frequencyLabels } from "./icalconstants";
import { FormControl, FormLabel, Stack, TextField } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function Frequency({ state, onChange }) {
  return (
    <Stack gap={2}>
      <FormControl>
        <FormLabel>Frequency:</FormLabel>
        <SimpleRadioGroup
          value={state.FREQ}
          onChange={(v) => onChange({ FREQ: v })}
          options={[
            { label: "Daily", value: "DAILY" },
            { label: "Weekly", value: "WEEKLY" },
            { label: "Monthly", value: "MONTHLY" },
          ]}
        />
      </FormControl>
      <Stack gap={1} direction="row" alignItems="center">
        <div>Every</div>
        <TextField
          label="Interval"
          value={state.INTERVAL}
          type="number"
          variant="outlined"
          fullWidth
          required
          sx={{ maxWidth: 200 }}
          onChange={(v) => onChange({ INTERVAL: Number(v.target.value) })}
        />
        <div>{frequencyLabels[state.FREQ]}</div>
      </Stack>
      {frequencyMap[state.FREQ]({ state, onChange })}
    </Stack>
  );
}

const frequencyMap = {
  DAILY: FrequencyDaily,
  WEEKLY: FrequencyWeekly,
  MONTHLY: FrequencyMonthly,
  "": () => null,
};
