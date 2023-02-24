import { Typography } from "@mui/material";
import merge from "lodash/merge";
import React from "react";

export default function Unavailable({ ...props }) {
  const typoProps = merge({ variant: "body2", color: "textSecondary" }, props);
  return <Typography {...typoProps}>Unavailable</Typography>;
}
