import { Stack } from "@mui/material";
import React from "react";

/**
 * Stack that is a column at xs and a row at larger sizes.
 * @param {'sm'|'md'|'lg'} rowAt= Use a row stack at this size and larger. Default to 'sm'.
 * @param rest Passed to Stack.
 */
export default function ResponsiveStack({ rowAt, ...rest }) {
  rowAt = rowAt || "sm";
  return <Stack direction={{ xs: "column", [rowAt]: "row" }} spacing={2} {...rest} />;
}
