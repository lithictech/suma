import Link from "../components/Link";
import { useUser } from "../hooks/user";
import StorefrontIcon from "@mui/icons-material/Storefront";
import {
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
} from "@mui/material";
import Divider from "@mui/material/Divider";
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
