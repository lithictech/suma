import ErrorScreen from "./components/ErrorScreen";
import LayoutContainer from "./components/LayoutContainer";
import PrivacyPolicyContent from "./components/PrivacyPolicyContent";
import ScreenLoader from "./components/ScreenLoader";
import history from "./history";
import {
  redirectIfAuthed,
  redirectIfUnauthed,
  redirectIfBoarded,
  redirectIfUnboarded,
} from "./hocs/authRedirects";
import { t } from "./localization";
import I18nProvider from "./localization/I18nProvider";
import useI18n from "./localization/useI18n";
import ContactListAdd from "./pages/ContactListAdd";
import ContactListHome from "./pages/ContactListHome";
import ContactListSuccess from "./pages/ContactListSuccess";
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
import PreferencesAuthed from "./pages/PreferencesAuthed";
import PreferencesPublic from "./pages/PreferencesPublic";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import PrivateAccountsList from "./pages/PrivateAccountsList";
import RegainAccountAccess from "./pages/RegainAccountAccess.jsx";
import Start from "./pages/Start";
import Styleguide from "./pages/Styleguide";
import TripDetail from "./pages/TripDetail.jsx";
import Trips from "./pages/Trips";
import UnclaimedOrderList from "./pages/UnclaimedOrderList";
import Utilities from "./pages/Utilities";
import applyHocs from "./shared/applyHocs";
import { installPromiseExtras } from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import BackendGlobalsProvider from "./state/BackendGlobalsProvider";
import ErrorToastProvider from "./state/ErrorToastProvider";
import GlobalViewStateProvider from "./state/GlobalViewStateProvider";
import OfferingProvider from "./state/OfferingProvider";
import ScreenLoaderProvider from "./state/ScreenLoaderProvider";
import UserProvider from "./state/UserProvider";
import withMetatags from "./state/withMetatags";
import withPageLayout from "./state/withPageLayout";
import withProps from "./state/withProps";
import withScreenLoaderMount from "./state/withScreenLoaderMount";
import React from "react";
import { HelmetProvider } from "react-helmet-async";
import { unstable_HistoryRouter as Router, Routes, Route } from "react-router-dom";

installPromiseExtras(window.Promise);

export default function App() {
  return (
    <GlobalViewStateProvider>
      <ErrorToastProvider>
        <BackendGlobalsProvider>
          <UserProvider>
            <I18nProvider>
              <ScreenLoaderProvider>
                <RerenderOnLangChange>
                  <HelmetProvider>
                    <OfferingProvider>
                      <InnerApp />
                    </OfferingProvider>
                  </HelmetProvider>
                </RerenderOnLangChange>
              </ScreenLoaderProvider>
            </I18nProvider>
          </UserProvider>
        </BackendGlobalsProvider>
      </ErrorToastProvider>
    </GlobalViewStateProvider>
  );
}

/**
 * Language choice has implicit state dependencies,
 * since API calls are done in the user's current language.
 * To avoid having a web of state modifications, we can just rebuild the DOM
 * and make all new API requests when language changes.
 *
 * This is really only needed for cross-screen API call state, like useOffering.
 * Components in the UI itself usually end up being redraw,
 * but contexts at a higher level would not be.
 *
 * This component must be placed outside of any localized API calls.
 */
function RerenderOnLangChange({ children }) {
  const { currentLanguage } = useI18n();
  return <React.Fragment key={currentLanguage}>{children}</React.Fragment>;
}

function InnerApp() {
  const { initializing } = useI18n();
  return initializing ? <ScreenLoader show /> : <AppRoutes />;
}

function AppRoutes() {
  return (
    <Router basename={import.meta.env.BASE_URL} history={history}>
      <Routes>
        <Route
          path="/"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("common.welcome_to_suma"), exact: true }),
            withPageLayout({ nav: "none", bg: "bg-white" }),
            Home
          )}
        />
        <Route
          path="/privacy-policy"
          exact
          element={renderWithHocs(withPageLayout({ noScrollTop: true }), PrivacyPolicy)}
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
            withProps({
              languageFile: "terms_of_use_and_sale",
            }),
            MarkdownContent
          )}
        />

        <Route
          path="/start"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.start") }),
            withPageLayout({ gutters: true, top: true }),
            Start
          )}
        />
        <Route
          path="/regain-account-access"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("auth.access_account_title") }),
            withPageLayout({ gutters: true, top: true }),
            RegainAccountAccess
          )}
        />
        <Route
          path="/regain-account-access/success"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("auth.access_account_title") }),
            withPageLayout({ gutters: true, top: true }),
            withProps({ success: true }),
            RegainAccountAccess
          )}
        />
        <Route
          path="/one-time-password"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.otp") }),
            withPageLayout({ gutters: true, top: true }),
            OneTimePassword
          )}
        />
        <Route
          path="/onboarding"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles.onboarding") }),
            withPageLayout(),
            Onboarding
          )}
        />
        <Route
          path="/onboarding/signup"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles.onboarding_signup") }),
            withPageLayout({ gutters: true, top: true }),
            OnboardingSignup
          )}
        />
        <Route
          path="/onboarding/finish"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            withMetatags({ title: t("titles.onboarding_finish") }),
            withPageLayout({ gutters: true, top: true }),
            OnboardingFinish
          )}
        />
        <Route
          path="/contact-list"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list"), exact: true }),
            withPageLayout({ nav: "none", bg: "bg-white" }),
            ContactListHome
          )}
        />
        <Route
          path="/contact-list/add"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list_signup") }),
            withPageLayout({ gutters: true, top: true }),
            ContactListAdd
          )}
        />
        <Route
          path="/contact-list/success"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list_finish") }),
            withPageLayout({ gutters: true, top: true }),
            ContactListSuccess
          )}
        />
        <Route
          path="/dashboard"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.dashboard") }),
            withPageLayout({ appNav: true }),
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
            withMetatags({ title: t("mobility.title") }),
            withPageLayout({ noBottom: true, appNav: true }),
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
            withMetatags({ title: t("food.title") }),
            withPageLayout({ gutters: false, top: false, appNav: true }),
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
            withMetatags({ title: t("food.title") }),
            FoodList
          )}
        />
        <Route
          path="/product/:offeringId/:productId"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.title") }),
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
            withMetatags({ title: t("food.cart_title") }),
            withPageLayout({ gutters: false, top: true }),
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
            withMetatags({ title: t("food.checkout") }),
            withPageLayout({ gutters: false, top: true }),
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
            withMetatags({ title: t("food.checkout") }),
            withPageLayout({ appNav: true, gutters: false }),
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
            withMetatags({ title: t("utilities.title") }),
            withPageLayout({ appNav: true }),
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
            withMetatags({ title: t("titles.funding") }),
            withPageLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("payments.link_bank_account") }),
            withPageLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("payments.add_card") }),
            withPageLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("payments.add_funds") }),
            withPageLayout({ top: true, gutters: true }),
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
            withMetatags({ title: t("titles.ledgers_overview") }),
            withPageLayout(),
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
            withMetatags({ title: t("titles.order_history") }),
            withPageLayout(),
            OrderHistoryList
          )}
        />
        <Route
          path="/unclaimed-orders"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.unclaimed_order_history_title") }),
            withPageLayout(),
            UnclaimedOrderList
          )}
        />
        <Route
          path="/order/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.order") }),
            withPageLayout(),
            OrderHistoryDetail
          )}
        />
        <Route
          path="/private-accounts"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.private_accounts") }),
            withPageLayout(),
            PrivateAccountsList
          )}
        />
        <Route
          path="/trips"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.trips") }),
            withPageLayout({ top: true, gutters: false }),
            Trips
          )}
        />
        <Route
          path="/trip/:id"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.trip_detail") }),
            withPageLayout({ top: true, gutters: false }),
            TripDetail
          )}
        />
        <Route
          path="/preferences"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.preferences") }),
            withPageLayout({ top: true, gutters: true }),
            PreferencesAuthed
          )}
        />
        <Route
          path="/preferences-public"
          exact
          element={renderWithHocs(
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.messaging_preferences") }),
            withPageLayout({ top: true, gutters: true }),
            PreferencesPublic
          )}
        />
        <Route
          path="/error"
          exact
          element={renderWithHocs(
            withMetatags({ title: t("common.error") }),
            withPageLayout(),
            () => (
              <LayoutContainer top>
                <ErrorScreen />
              </LayoutContainer>
            )
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
