import { Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";

export default function FormLayout({ title, subtitle, onSubmit, children }) {
  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        {title}
      </Typography>
      <Typography variant="body1" gutterBottom>
        {subtitle}
      </Typography>
      <Box component="form" mt={2} onSubmit={onSubmit}>
        {children}
      </Box>
    </div>
  );
}
