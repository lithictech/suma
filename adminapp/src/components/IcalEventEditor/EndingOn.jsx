import SafeDateTimePicker from "../SafeDateTimePicker";
import React from "react";

/**
 * @param {IcalRruleState} state
 * @param {function(object): void} onChange
 */
export default function EndingOn({ state, onChange }) {
  return (
    <SafeDateTimePicker
      label="End On"
      value={state.UNTIL || null}
      onChange={(v) => onChange({ UNTIL: v })}
    />
  );
}
