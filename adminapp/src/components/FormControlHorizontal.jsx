import { FormControl, FormLabel } from "@mui/material";
import React from "react";

/**
 * Lay out a label and form control side-by-side rather than stacked.
 * Sort of silly MUI can't handle this but here we are.
 *
 * The child is cloned with an aria-labelledby pointing at the label,
 * so grouped controls (like RadioGroup) get an accessible name.
 */
export default function FormControlHorizontal({ label, children }) {
  const labelId = React.useId();
  const child = React.isValidElement(children)
    ? React.cloneElement(children, {
        "aria-labelledby": children.props["aria-labelledby"] || labelId,
      })
    : children;
  return (
    <FormControl
      sx={{
        flexDirection: "row",
        alignItems: "center",
        gap: 2,
      }}
    >
      <FormLabel id={labelId} sx={{ mb: 0 }}>
        {label}
      </FormLabel>
      {child}
    </FormControl>
  );
}
