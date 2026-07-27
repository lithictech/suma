import { Card, CardContent, Stack } from "@mui/material";
import React from "react";

export default function SimpleCard({ spacing, children }) {
  let ch = children;
  if (spacing) {
    ch = <Stack spacing={spacing}>{children}</Stack>;
  }
  return (
    <Card>
      <CardContent>{ch}</CardContent>
    </Card>
  );
}
