import ScreenLoader from "./components/ScreenLoader";
import {
  redirectIfAuthed,
  redirectIfUnauthed,
  redirectIfBoarded,
  redirectIfUnboarded,
} from "./hocs/authRedirects";
import useI18Next from "./localization/useI18Next";
import Dashboard from "./pages/Dashboard";
import Funding from "./pages/Funding";
import FundingAddFunds from "./pages/FundingAddFunds";
import FundingLinkBankAccount from "./pages/FundingLinkBankAccount";
import Home from "./pages/Home";
import LedgersOverview from "./pages/LedgersOverview";
import MapPage from "./pages/MapPage";
import Onboarding from "./pages/Onboarding";
import OnboardingFinish from "./pages/OnboardingFinish";
import OnboardingSignup from "./pages/OnboardingSignup";
import OneTimePassword from "./pages/OneTimePassword";
import Start from "./pages/Start";
import Styleguide from "./pages/Styleguide";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import {
  ScreenLoaderProvider,
  withScreenLoaderMount,
  withMetatags,
} from "./state/useScreenLoader";
import { UserProvider } from "./state/useUser";
import React from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

window.Promise = bluejay.Promise;

export default function App() {
  const { i18nextLoading } = useI18Next();
  return (
    <ScreenLoaderProvider>
      <UserProvider>
        {i18nextLoading ? <ScreenLoader show /> : <AppRoutes />}
      </UserProvider>
    </ScreenLoaderProvider>
  );
}

function AppRoutes() {
  return (
    <Router basename={process.env.PUBLIC_URL}>
      <Routes>
        <Route
          path="/"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: "Welcome to Suma!", exact: true }),
            Home
          )}
        />
        <Route
          path="/start"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: "Get Started" }),
            Start
          )}
        />
        <Route
          path="/one-time-password"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: "One Time Password" }),
            OneTimePassword
          )}
        />
        <Route
          path="/onboarding"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: "One Time Password" }),
            Onboarding
          )}
        />
        <Route
          path="/onboarding/signup"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: "Onboarding Signup" }),
            OnboardingSignup
          )}
        />
        <Route
          path="/onboarding/finish"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            withMetatags({ title: "Onboarding Finish" }),
            OnboardingFinish
          )}
        />
        <Route
          path="/dashboard"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Dashboard" }),
            Dashboard
          )}
        />
        <Route
          path="/map"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Mobility Services" }),
            MapPage
          )}
        />
        <Route
          path="/funding"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Funding" }),
            Funding
          )}
        />
        <Route
          path="/link-bank-account"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Link Bank Account" }),
            FundingLinkBankAccount
          )}
        />
        <Route
          path="/add-funds"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Add Funds" }),
            FundingAddFunds
          )}
        />
        <Route
          path="/ledgers"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: "Ledgers Overview" }),
            LedgersOverview
          )}
        />
        <Route path="/styleguide" exact element={<Styleguide />} />
        <Route path="/*" element={<Redirect to="/" />} />
      </Routes>
    </Router>
  );
}

function renderWithHocs(...args) {
  return renderComponent(applyHocs(...args));
}
