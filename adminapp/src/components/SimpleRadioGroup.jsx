import { FormControlLabel, Radio, RadioGroup } from "@mui/material";
import React from "react";

/**
 * @param {string} value
 * @param {function(string): void} onChange
 * @param {Array<{label: string, value: string}>} options
 * @param {string=} labelId Id of the element labelling this group (usually a FormLabel).
 * @param rest Passed to RadioGroup.
 */
export default function SimpleRadioGroup({ value, onChange, options, labelId, ...rest }) {
  return (
    <RadioGroup
      value={value}
      row
      aria-labelledby={labelId}
      onChange={(e) => onChange(e.target.value)}
      {...rest}
    >
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
