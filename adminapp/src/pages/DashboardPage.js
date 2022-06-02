import Link from "../components/Link";
import useGlobalStyles from "../hooks/useGlobalStyles";
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
import { makeStyles } from "@mui/styles";
import React from "react";

const useStyles = makeStyles((theme) => ({
  row: {
    display: "flex",
    flexDirection: "row",
  },
}));

export default function DashboardPage() {
  const globalClasses = useGlobalStyles();
  const classes = useStyles();
  const { user } = useUser();
  return (
    <Container className={globalClasses.root} maxWidth="lg">
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
