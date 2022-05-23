import Link from "../components/Link";
import { useUser } from "../hooks/user";
import navLinks from "../modules/navLinks";
import { Container, Typography } from "@mui/material";
import { makeStyles } from "@mui/styles";
import React from "react";

const useStyles = makeStyles((theme) => ({
  root: {
    marginTop: theme.spacing(5),
  },
  row: {
    display: "flex",
    flexDirection: "row",
  },
}));

export default function DashboardPage() {
  const classes = useStyles();
  const { user } = useUser();
  return (
    <Container className={classes.root} maxWidth="lg">
      <Typography gutterBottom>Hello, {user.name}</Typography>
      <div className={classes.row}>
        <ul>
          {navLinks.map(({ label, href }) => (
            <li key={label}>
              <Link to={href}>{label}</Link>
            </li>
          ))}
        </ul>
      </div>
    </Container>
  );
}
