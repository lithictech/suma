import ResponsiveStack from "../ResponsiveStack";
import SafeDateTimePicker from "../SafeDateTimePicker";
import React from "react";

export default function StartEnd({ start, end, onChange }) {
  return (
    <ResponsiveStack>
      <SafeDateTimePicker
        label="Event Start"
        value={start || null}
        onChange={(v) => onChange("start", v)}
      />
      <SafeDateTimePicker
        label="Event End"
        value={end || null}
        onChange={(v) => onChange("end", v)}
      />
    </ResponsiveStack>
  );
}
