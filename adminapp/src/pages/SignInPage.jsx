import api from "../api";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { useUser } from "../hooks/user";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import {
  Button,
  Card,
  CardContent,
  FormControl,
  TextField,
  Container,
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
    <Container>
      <ScrollTopOnMount top={0} />
      <Card className={classes.card}>
        <CardContent>
          <form noValidate onSubmit={onSubmit}>
            <FormControl margin="normal" required fullWidth>
              <TextField
                label="Email Address"
                required
                type="email"
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
                variant="outlined"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </FormControl>
            <Button variant="contained" color="primary" role="submit" onClick={onSubmit}>
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
