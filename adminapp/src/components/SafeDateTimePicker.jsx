import { dayjsOrNull } from "../modules/dayConfig";
import { DateTimePicker } from "@mui/x-date-pickers";
import React from "react";

/**
 * DateTimePicker with some better defaults:
 * - 100% width (pass in 'sx.width' to override).
 * - closeOnSelect is true (pass 'closeOnSelect=false' to override).
 * - If 'views' is not given, then trucate the 'seconds' from the given dayjs value.
 *   This prevents having hidden, un-editable seconds from persisting.
 *   To add seconds to the default views, pass 'seconds=true', and do not pass 'views'.
 * @param {*} value Null, dayjs, or anything that can be be passed to dayjs(value).
 * @param {boolean=} seconds
 * @param {Array<string>=}= views
 * @param {object=} sx
 * @param {object=} rest
 */
export default function SafeDateTimePicker({ value, seconds, views, sx, ...rest }) {
  views = views || DEFAULT_VIEWS;
  if (seconds && !views.includes("seconds")) {
    views = [...views, "seconds"];
  }
  value = dayjsOrNull(value);
  if (!views.includes("seconds")) {
    value = value?.second(0);
  }
  return (
    <DateTimePicker
      value={value}
      views={views}
      closeOnSelect
      sx={{ width: "100%", ...sx }}
      {...rest}
    />
  );
}

const DEFAULT_VIEWS = ["year", "month", "day", "hours", "minutes"];
