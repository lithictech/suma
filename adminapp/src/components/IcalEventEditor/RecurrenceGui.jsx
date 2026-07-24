import Ending from "./Ending";
import Frequency from "./Frequency";
import { Stack } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function RecurrenceGui({ state, onChange }) {
  return (
    <Stack gap={2}>
      <Frequency state={state} onChange={onChange} />
      <Ending state={state} onChange={onChange} />
    </Stack>
  );
}
