import { Stack } from "@mui/material";
import React from "react";

export default function ResponsiveStack({ ...rest }) {
  return <Stack direction={{ xs: "column", sm: "row" }} spacing={2} {...rest} />;
}
