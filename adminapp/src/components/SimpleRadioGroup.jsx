import { FormControlLabel, Radio, RadioGroup } from "@mui/material";
import React from "react";

/**
 * @param {string} value
 * @param {function(string): void} onChange
 * @param {Array<{label: string, value: string}>} options
 */
export default function SimpleRadioGroup({ value, onChange, options }) {
  return (
    <RadioGroup value={value} row onChange={(e) => onChange(e.target.value)}>
      {options.map((o) => (
        <FormControlLabel
          key={o.value}
          value={o.value}
          control={<Radio />}
          label={o.label}
        />
      ))}
    </RadioGroup>
  );
}
