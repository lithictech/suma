import { Typography } from "@mui/material";
import _ from "lodash";
import React from "react";

export default function Unavailable({ ...props }) {
  const typoProps = _.merge({ variant: "body2", color: "textSecondary" }, props);
  return <Typography {...typoProps}>Unavailable</Typography>;
}
