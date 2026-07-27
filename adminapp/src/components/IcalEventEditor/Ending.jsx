import SimpleRadioGroup from "../SimpleRadioGroup";
import EndingAfter from "./EndingAfter";
import EndingOn from "./EndingOn";
import { endModes } from "./icalconstants";
import { FormControl, FormLabel, Stack } from "@mui/material";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function Ending({ state, onChange }) {
  const [endMode, setEndModeInner] = React.useState(endModes[0]);
  const setEndMode = React.useCallback(
    (v) => {
      setEndModeInner(v);
      if (v === "after") {
        onChange({ UNTIL: null });
      } else if (v === "on") {
        onChange({ COUNT: 0 });
      }
    },
    [onChange]
  );
  return (
    <Stack spacing={2}>
      <Stack gap={2}>
        <FormControl>
          <FormLabel>End After:</FormLabel>
          <SimpleRadioGroup
            value={endMode}
            row
            onChange={setEndMode}
            options={[
              { label: "Occurrences", value: "after" },
              { label: "Date", value: "on" },
            ]}
          />
        </FormControl>
        {endModeMap[endMode]({ state, onChange })}
      </Stack>
    </Stack>
  );
}

const endModeMap = { after: EndingAfter, on: EndingOn, "": () => null };
