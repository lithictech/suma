import { useUser } from "../hooks/user";
import { Typography } from "@mui/material";
import React from "react";

export default function DashboardPage() {
  const { user } = useUser();
  return (
    <>
      <Typography variant="h6" gutterBottom>
        Hello, {user.name}
      </Typography>
      <Typography gutterBottom>
        Use the navigation menu on the top-left to access resources.
      </Typography>
    </>
  );
}
