import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import {
  Button,
  Card,
  CardContent,
  Container,
  FormControl,
  TextField,
  Typography,
} from "@mui/material";
import { makeStyles } from "@mui/styles";
import React from "react";

export default function SignInPage() {
  const { setUser } = useUser();
  const [email, setEmail] = React.useState(placeholder.email);
  const [password, setPassword] = React.useState(placeholder.password);
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const classes = useStyles();

  function onSubmit(e) {
    e.preventDefault();
    return api
      .signIn({ email, password })
      .then(api.pickData)
      .then((data) => setUser(data))
      .catch(enqueueErrorSnackbar);
  }

  return (
    <Container component="main">
      <ScrollTopOnMount top={0} />
      <Card className={classes.card}>
        <CardContent>
          <Typography component="h1" variant="h5" gutterBottom>
            Sign in
          </Typography>
          <form noValidate onSubmit={onSubmit}>
            <FormControl margin="normal" required fullWidth>
              <TextField
                label="Email Address"
                required
                type="email"
                autoComplete="username"
                value={email}
                variant="outlined"
                onChange={(e) => setEmail(e.target.value)}
              />
            </FormControl>
            <FormControl margin="normal" required fullWidth>
              <TextField
                label="Password"
                required
                type="password"
                autoComplete="current-password"
                variant="outlined"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </FormControl>
            <Button variant="contained" color="primary" type="submit">
              Sign In
            </Button>
          </form>
        </CardContent>
      </Card>
    </Container>
  );
}

const useStyles = makeStyles((theme) => ({
  card: {
    marginTop: theme.spacing(2),
  },
  title: {
    textAlign: "center",
  },
  submitButton: {
    marginTop: theme.spacing(3),
  },
}));

const placeholder =
  import.meta.env.NODE_ENV === "development"
    ? { email: "admin@lithic.tech", password: "Password1!" }
    : { email: "", password: "" };
