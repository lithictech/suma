import PrivacyPolicyContent from "./components/PrivacyPolicyContent";
import ScreenLoader from "./components/ScreenLoader";
import {
  redirectIfAuthed,
  redirectIfUnauthed,
  redirectIfBoarded,
  redirectIfUnboarded,
} from "./hocs/authRedirects";
import { t } from "./localization";
import useI18Next, { I18NextProvider } from "./localization/useI18Next";
import Dashboard from "./pages/Dashboard";
import Food from "./pages/Food";
import FoodCart from "./pages/FoodCart";
import FoodCheckout from "./pages/FoodCheckout";
import FoodCheckoutConfirmation from "./pages/FoodCheckoutConfirmation";
import FoodDetails from "./pages/FoodDetails";
import FoodList from "./pages/FoodList";
import Funding from "./pages/Funding";
import FundingAddCard from "./pages/FundingAddCard";
import FundingAddFunds from "./pages/FundingAddFunds";
import FundingLinkBankAccount from "./pages/FundingLinkBankAccount";
import Home from "./pages/Home";
import LedgersOverview from "./pages/LedgersOverview";
import MarkdownContent from "./pages/MarkdownContent";
import Mobility from "./pages/Mobility";
import Onboarding from "./pages/Onboarding";
import OnboardingFinish from "./pages/OnboardingFinish";
import OnboardingSignup from "./pages/OnboardingSignup";
import OneTimePassword from "./pages/OneTimePassword";
import OrderHistoryDetail from "./pages/OrderHistoryDetail";
import OrderHistoryList from "./pages/OrderHistoryList";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import Start from "./pages/Start";
import Styleguide from "./pages/Styleguide";
import Utilities from "./pages/Utilities";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import { BackendGlobalsProvider } from "./state/useBackendGlobals";
import { ErrorToastProvider } from "./state/useErrorToast";
import { GlobalViewStateProvider } from "./state/useGlobalViewState";
import { OfferingProvider } from "./state/useOffering";
import { ScreenLoaderProvider, withScreenLoaderMount } from "./state/useScreenLoader";
import { UserProvider } from "./state/useUser";
import withLayout from "./state/withLayout";
import withMetatags from "./state/withMetatags";
import withProps from "./state/withProps";
import React from "react";
import { HelmetProvider } from "react-helmet-async";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";

window.Promise = bluejay.Promise;

export default function App() {
  return (
    <GlobalViewStateProvider>
      <ErrorToastProvider>
        <BackendGlobalsProvider>
          <UserProvider>
            <I18NextProvider>
              <ScreenLoaderProvider>
                <HelmetProvider>
                  <OfferingProvider>
                    <InnerApp />
                  </OfferingProvider>
                </HelmetProvider>
              </ScreenLoaderProvider>
            </I18NextProvider>
          </UserProvider>
        </BackendGlobalsProvider>
      </ErrorToastProvider>
    </GlobalViewStateProvider>
  );
}

function InnerApp() {
  const { i18nextLoading } = useI18Next();
  return i18nextLoading ? <ScreenLoader show /> : <AppRoutes />;
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
            withMetatags({ title: t("common:welcome_to_suma"), exact: true }),
            withLayout({ nav: "none", bg: "bg-white" }),
            Home
          )}
        />
        <Route
          path="/privacy-policy"
          exact
          element={renderWithHocs(withLayout({ noScrollTop: true }), PrivacyPolicy)}
        />
        <Route
          path="/privacy-policy-content"
          exact
          element={renderWithHocs(PrivacyPolicyContent)}
        />
        <Route
          path="/terms-of-use"
          exact
          element={renderWithHocs(
            withProps({ namespace: "terms_of_use" }),
            MarkdownContent
          )}
        />
        <Route
          path="/terms-of-sale-holiday-2022"
          exact
          element={renderWithHocs(
            withProps({ namespace: "terms_of_sale_holiday_2022" }),
            MarkdownContent
          )}
        />

        <Route
          path="/start"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles:start") }),
            withLayout({ gutters: true, top: true }),
            Start
          )}
        />
        <Route
          path="/one-time-password"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles:otp") }),
            withLayout({ gutters: true, top: true }),
            OneTimePassword
          )}
        />
        <Route
          path="/onboarding"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles:onboarding") }),
            withLayout({}),
            Onboarding
          )}
        />
        <Route
          path="/onboarding/signup"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles:onboarding_signup") }),
            withLayout({ gutters: true, top: true }),
            OnboardingSignup
          )}
        />
        <Route
          path="/onboarding/finish"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            withMetatags({ title: t("titles:onboarding_finish") }),
            withLayout({ gutters: true, top: true }),
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
            withMetatags({ title: t("titles:dashboard") }),
            withLayout({ appNav: true }),
            Dashboard
          )}
        />
        <Route
          path="/mobility"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("mobility:title") }),
            withLayout({ noBottom: true, appNav: true }),
            Mobility
          )}
        />
        <Route
          path="/food"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:title") }),
            withLayout({ gutters: false, top: false, appNav: true }),
            Food
          )}
        />
        <Route
          path="/food/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:title") }),
            withLayout({ gutters: false, top: false, appNav: true }),
            FoodList
          )}
        />
        <Route
          path="/product/:offeringId-:productId"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:title") }),
            withLayout({ gutters: false, top: false }),
            FoodDetails
          )}
        />
        <Route
          path="/cart/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:cart_title") }),
            withLayout({ gutters: false, top: true }),
            FoodCart
          )}
        />
        <Route
          path="/checkout/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:checkout") }),
            withLayout({ gutters: true, top: true }),
            FoodCheckout
          )}
        />
        <Route
          path="/checkout/:id/confirmation"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food:checkout") }),
            withLayout({ appNav: true, gutters: false }),
            FoodCheckoutConfirmation
          )}
        />

        <Route
          path="/utilities"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("utilities:title") }),
            withLayout({ appNav: true }),
            Utilities
          )}
        />
        <Route
          path="/funding"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles:funding") }),
            withLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("payments:link_bank_account") }),
            withLayout({ top: true, gutters: true }),
            FundingLinkBankAccount
          )}
        />
        <Route
          path="/add-card"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("payments:add_card") }),
            withLayout({ top: true, gutters: true }),
            FundingAddCard
          )}
        />
        <Route
          path="/add-funds"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("payments:add_funds") }),
            withLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("titles:ledgers_overview") }),
            withLayout(),
            LedgersOverview
          )}
        />
        <Route
          path="/order-history"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles:ledgers_overview") }),
            withLayout(),
            OrderHistoryList
          )}
        />
        <Route
          path="/order/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles:ledgers_overview") }),
            withLayout(),
            OrderHistoryDetail
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
