import TopNav from "./components/TopNav";
import { redirectIfAuthed, redirectIfUnauthed } from "./hocs/authRedirects";
import { UserProvider } from "./hooks/user";
import DashboardPage from "./pages/DashboardPage";
import SignInPage from "./pages/SignInPage";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import renderComponent from "./shared/react/renderComponent";
import theme from "./theme";
import { ThemeProvider } from "@mui/material";
import { SnackbarProvider } from "notistack";
import React from "react";
import { Route, BrowserRouter as Router, Routes } from "react-router-dom";

window.Promise = bluejay.Promise;

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <SnackbarProvider>
        <UserProvider>
          <Router>
            <NavSwitch />
            <PageSwitch />
          </Router>
        </UserProvider>
      </SnackbarProvider>
    </ThemeProvider>
  );
}

function NavSwitch() {
  return (
    <Routes>
      <Route exact path="/" element={null} />
      <Route exact path="/sign-in" element={null} />
      <Route exact path="*" element={<TopNav />} />
    </Routes>
  );
}

function PageSwitch() {
  return (
    <Routes>
      <Route
        exact
        path="/sign-in"
        element={renderWithHocs(redirectIfAuthed, SignInPage)}
      />
      <Route
        exact
        path="/dashboard"
        element={renderWithHocs(redirectIfUnauthed, DashboardPage)}
      />
      <Route
        path="/"
        element={renderWithHocs(redirectIfAuthed, redirectIfUnauthed, () => null)}
      />
    </Routes>
  );
}

function renderWithHocs(...args) {
  return renderComponent(applyHocs(...args));
}
