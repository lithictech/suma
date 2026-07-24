import { TextField } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function EndingAfter({ state, onChange }) {
  return (
    <TextField
      label="Occurrences"
      value={state.COUNT}
      type="number"
      variant="outlined"
      fullWidth
      required
      onChange={(v) => onChange({ COUNT: Number(v.target.value) })}
    />
  );
}
