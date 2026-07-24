import api from "../../api";
import formatDate from "../../modules/formatDate";
import useAsyncFetch from "../../shared/react/useAsyncFetch";
import { icalDate, renderRruleState } from "./icalconstants";
import { Typography } from "@mui/material";
import size from "lodash/size";
import React from "react";

export default function Output({ start, end, rrule }) {
  const rruleStr = renderRruleState(rrule);
  const project = React.useCallback(
    () =>
      api.projectIcalEvents({
        begin: start.format(),
        end: end.format(),
        rrule: rruleStr,
      }),
    [end, rruleStr, start]
  );
  const { state } = useAsyncFetch(project, {
    default: {},
    pickData: true,
  });

  return (
    <div>
      <Typography sx={{ fontWeight: "bold" }}>Output:</Typography>
      <code>
        DTSTART:
        {start && icalDate(start)}
        <br />
        DTEND:
        {end && icalDate(end)}
        <br />
        RRULE:{rruleStr}
      </code>

      <Typography sx={{ fontWeight: "bold" }}>
        Occurrences ({size(state.occurrences)}):
      </Typography>
      <ul style={{ marginTop: 0 }}>
        {state.occurrences?.map(({ begin, end }) => (
          <li key={begin + end}>
            {formatDate(begin)} - {formatDate(end)}
          </li>
        ))}
      </ul>
    </div>
  );
}
