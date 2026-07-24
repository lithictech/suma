import { Typography } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function FrequencyMonthly({ state, onChange }) {
  return (
    <Typography color="error">
      Further recurrence controls have not been developed yet. Let the devs know you need
      this, and then use the Advanced recurrence editor.
    </Typography>
  );
}
