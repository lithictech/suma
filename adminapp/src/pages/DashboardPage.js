import Link from "../components/Link";
import useStyles from "../hooks/useStyles";
import { useUser } from "../hooks/user";
import navLinks from "../modules/navLinks";
import {
  Container,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
} from "@mui/material";
import React from "react";

export default function DashboardPage() {
  const classes = useStyles();
  const { user } = useUser();
  return (
    <Container className={classes.root} maxWidth="lg">
      <Typography gutterBottom>Hello, {user.name}</Typography>
      <div className={classes.row}>
        <List>
          {navLinks.map(({ label, href, icon }) => (
            <ListItem key={label} disablePadding>
              <ListItemButton component={Link} href={href}>
                <ListItemIcon>{icon}</ListItemIcon>
                <ListItemText primary={label} />
              </ListItemButton>
            </ListItem>
          ))}
        </List>
      </div>
    </Container>
  );
}
