import api from "../../api";
import useErrorSnackbar from "../../hooks/useErrorSnackbar";
import { dayjsOrNull } from "../../modules/dayConfig";
import { icalRruleState, renderRruleState } from "./icalconstants";
import IcalEventEditor from "./index";
import LoadingButton from "@mui/lab/LoadingButton";
import { Button, Dialog, DialogTitle, DialogContent, DialogActions } from "@mui/material";
import React from "react";

/**
 * Use the event editor to generate a list of occurrences,
 * then commit them back. Used when we want to use ical to
 * generate recurrence objects but not save the ical info directly.
 * Widget is shown in a modal, we can refactor in the future if needed.
 *
 * @param {Toggle} toggle
 * @param {string} title
 * @param {{start, end}[]} ranges
 * @param {function({start: string, end: string}[])} onCommit
 */
export default function IcalEventOccurrencesEditor({ toggle, title, ranges, onCommit }) {
  const [loading, setLoading] = React.useState(false);
  const { enqueueErrorSnackbar } = useErrorSnackbar();

  const [start, setStart] = React.useState(dayjsOrNull(ranges[0]?.start));
  const [end, setEnd] = React.useState(dayjsOrNull(ranges[0]?.end));

  const [rrule, setRrule] = React.useState({
    ...icalRruleState(),
    FREQ: "WEEKLY",
    INTERVAL: 1,
    COUNT: ranges.length,
  });

  const handleAccept = React.useCallback(() => {
    api
      .projectIcalEvents({
        start: start?.format(),
        end: end?.format(),
        rrule: renderRruleState(rrule),
      })
      .then((r) => {
        onCommit(r.data.occurrences);
        setLoading(false);
        toggle.turnOff();
      })
      .catch((e) => {
        enqueueErrorSnackbar(e);
        setLoading(false);
      });
  }, [end, enqueueErrorSnackbar, onCommit, rrule, start, toggle]);

  return (
    <Dialog onClose={toggle.turnOff} open={toggle.isOn} maxWidth="md" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent sx={{ pt: "8px !important" }}>
        <IcalEventEditor
          start={start}
          end={end}
          rrule={rrule}
          onChange={(f, val) => {
            if (f === "start") {
              setStart(val);
            } else if (f === "end") {
              setEnd(val);
            } else {
              setRrule({ ...rrule, ...val });
            }
          }}
        />
      </DialogContent>
      <DialogActions>
        <Button variant="outlined" color="secondary" onClick={toggle.turnOff}>
          Cancel
        </Button>
        <LoadingButton loading={loading} onClick={handleAccept} variant="contained">
          Accept
        </LoadingButton>
      </DialogActions>
    </Dialog>
  );
}
