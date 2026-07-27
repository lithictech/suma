import SafeExternalLink from "../../shared/react/SafeExternalLink";
import { icalRruleState, parseIcalRrule, renderRruleState } from "./icalconstants";
import { TextField } from "@mui/material";
import has from "lodash/has";
import size from "lodash/size";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function RecurrenceAdvanced({ state, onChange }) {
  const [text, setText] = React.useState(renderRruleState(state));
  const onTextChange = React.useCallback(
    (e) => {
      const parsed = parseIcalRrule(e.target.value);
      const success =
        size(parsed) > 0 && Object.keys(parsed).every((k) => has(knownFields, k));
      setText(e.target.value);
      if (success) {
        onChange(parsed);
      }
    },
    [onChange]
  );
  return (
    <TextField
      label="RRULE"
      name="rrule"
      value={text}
      fullWidth
      helperText={
        <>
          Use{" "}
          <SafeExternalLink href="https://icalendar.org/rrule-tool.html">
            https://icalendar.org/rrule-tool.html
          </SafeExternalLink>{" "}
          to create an RRULE and then paste it here.
        </>
      }
      onChange={onTextChange}
    />
  );
}

const knownFields = icalRruleState();
