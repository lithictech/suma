import { FormControl, FormLabel } from "@mui/material";
import React from "react";

/**
 * Lay out a label and form control side-by-side rather than stacked.
 * Sort of silly MUI can't handle this but here we are.
 */
export default function FormControlHorizontal({ label, children }) {
  return (
    <FormControl
      sx={{
        flexDirection: "row",
        alignItems: "center",
        gap: 2,
      }}
    >
      <FormLabel sx={{ mb: 0 }}>{label}</FormLabel>
      {children}
    </FormControl>
  );
}
