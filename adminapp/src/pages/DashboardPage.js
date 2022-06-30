import { useUser } from "../hooks/user";
import MenuIcon from "@mui/icons-material/Menu";
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
        You can currently check member details, impersonate members and check their
        activity history. More features will be coming soon.
      </Typography>
      <Typography>
        Use the side drawer or click <MenuIcon sx={{ verticalAlign: "top" }} /> on the top
        left to navigate.
      </Typography>
    </>
  );
}
