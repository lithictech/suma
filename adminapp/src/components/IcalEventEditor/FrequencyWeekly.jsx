import { bydays, bydaysLabels } from "./icalconstants";
import { ToggleButton, ToggleButtonGroup } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function FrequencyWeekly({ state, onChange }) {
  const handleChange = (_event, newSelected) => {
    onChange({ BYDAY: newSelected });
  };

  return (
    <ToggleButtonGroup value={state.BYDAY} onChange={handleChange} fullWidth>
      {bydays.map((d) => (
        <ToggleButton key={d} value={d}>
          {bydaysLabels[d]}
        </ToggleButton>
      ))}
    </ToggleButtonGroup>
  );
}
