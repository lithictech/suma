import FormControlHorizontal from "../FormControlHorizontal";
import RecurrenceAdvanced from "./RecurrenceAdvanced";
import RecurrenceGui from "./RecurrenceGui";
import RecurrenceNone from "./RecurrenceNone";
import { FormControlLabel, Radio, RadioGroup, Stack } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} rrule
 * @param {function(object): void} onChange
 */
export default function Recurrence({ state, onChange }) {
  const [mode, setMode] = React.useState("gui");
  const Editor = editorMap[mode];
  return (
    <Stack gap={2}>
      <FormControlHorizontal label="Recurrence:">
        <RadioGroup value={mode} row onChange={(e) => setMode(e.target.value)}>
          <FormControlLabel value="none" control={<Radio />} label="None" />
          <FormControlLabel value="gui" control={<Radio />} label="GUI" />
          <FormControlLabel value="advanced" control={<Radio />} label="Advanced" />
        </RadioGroup>
      </FormControlHorizontal>
      <Editor state={state} onChange={onChange} />
    </Stack>
  );
}

const editorMap = {
  none: RecurrenceNone,
  gui: RecurrenceGui,
  advanced: RecurrenceAdvanced,
  "": () => null,
};
