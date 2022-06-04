import {
  redirectIfAuthed,
  redirectIfUnauthed,
  redirectIfBoarded,
  redirectIfUnboarded,
} from "./hocs/authRedirects";
import useI18Next from "./localization/useI18Next";
import Dashboard from "./pages/Dashboard";
import Home from "./pages/Home";
import LedgerPage from "./pages/LedgerPage";
import MapPage from "./pages/MapPage";
import Onboarding from "./pages/Onboarding";
import OnboardingFinish from "./pages/OnboardingFinish";
import OnboardingSignup from "./pages/OnboardingSignup";
import OneTimePassword from "./pages/OneTimePassword";
import Start from "./pages/Start";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import { UserProvider } from "./state/useUser";
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

window.Promise = bluejay.Promise;

function App() {
  const { i18nextLoading } = useI18Next();

  return (
    <UserProvider>
      {i18nextLoading ? (
        <div>Loading Suma!</div>
      ) : (
        <Router basename={process.env.PUBLIC_URL}>
          <Routes>
            <Route path="/" exact element={renderWithHocs(redirectIfAuthed, Home)} />
            <Route
              path="/start"
              exact
              element={renderWithHocs(redirectIfAuthed, Start)}
            />
            <Route
              path="/one-time-password"
              exact
              element={renderWithHocs(redirectIfAuthed, OneTimePassword)}
            />
            <Route
              path="/onboarding"
              exact
              element={renderWithHocs(redirectIfUnauthed, redirectIfBoarded, Onboarding)}
            />
            <Route
              path="/onboarding/signup"
              exact
              element={renderWithHocs(
                redirectIfUnauthed,
                redirectIfBoarded,
                OnboardingSignup
              )}
            />
            <Route
              path="/onboarding/finish"
              exact
              element={renderWithHocs(redirectIfUnauthed, OnboardingFinish)}
            />
            <Route
              path="/dashboard"
              exact
              element={renderWithHocs(redirectIfUnauthed, redirectIfUnboarded, Dashboard)}
            />
            <Route
              path="/ledger"
              exact
              element={renderWithHocs(
                redirectIfUnauthed,
                redirectIfUnboarded,
                LedgerPage
              )}
            />
            <Route
              path="/map"
              exact
              element={renderWithHocs(redirectIfUnauthed, redirectIfUnboarded, MapPage)}
            />
            <Route path="/*" element={<Redirect to="/" />} />
          </Routes>
        </Router>
      )}
    </UserProvider>
  );
}

export default App;

function renderWithHocs(...args) {
  return renderComponent(applyHocs(...args));
}
