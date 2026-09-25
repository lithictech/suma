import theme from "../theme";
import FormButtons from "./FormButtons";
import { Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";

export default function FormLayout({
  title,
  subtitle,
  onSubmit,
  isBusy,
  style,
  children,
}) {
  return (
    <div style={{ maxWidth: 650, ...style }}>
      <Typography variant="h4" gutterBottom>
        {title}
      </Typography>
      <Typography variant="body1" gutterBottom>
        {subtitle}
      </Typography>
      <Box component="form" mt={2} onSubmit={onSubmit}>
        {children}
        <div style={{ marginTop: theme.spacing(2) }}>
          <FormButtons back loading={isBusy} />
        </div>
      </Box>
    </div>
  );
}
