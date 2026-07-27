import Output from "./Output";
import Recurrence from "./Recurrence";
import StartEnd from "./StartEnd";
import { Stack } from "@mui/material";
import React from "react";

/**
 * Widget that can toggle between "GUI" and "advanced" modes for editing a VEVENT.
 *
 * GUI mode shows start and end times,
 * plus interval (daily, weekly, monthly) and occurrence limits (count vs. date).
 *
 * Advanced mode allows choosing the start and end times,
 * and provides a text input for the RRULE.
 *
 * @param {string|dayjs.Dayjs} start
 * @param {string|dayjs.Dayjs} end
 * @param {IcalRruleState} rruleState
 * @param {function('start'|'end'|'rrule', *): void} onChange Called with (field, value) on change.
 */
export default function IcalEventEditor({ start, end, rrule, onChange }) {
  return (
    <Stack spacing={2}>
      <StartEnd start={start} end={end} onChange={onChange} />
      <Recurrence state={rrule} onChange={(ch) => onChange("rrule", { ...ch })} />
      <Output start={start} end={end} rrule={rrule} />
    </Stack>
  );
}
