import ErrorScreen from "./components/ErrorScreen";
import LayoutContainer from "./components/LayoutContainer";
import PrivacyPolicyContent from "./components/PrivacyPolicyContent";
import ScreenLoader from "./components/ScreenLoader";
import {
  redirectIfAuthed,
  redirectIfUnauthed,
  redirectIfBoarded,
  redirectIfUnboarded,
} from "./hocs/authRedirects";
import { t } from "./localization";
import I18NextProvider from "./localization/I18NextProvider";
import useI18Next from "./localization/useI18Next";
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
import Start from "./pages/Start";
import Styleguide from "./pages/Styleguide";
import UnclaimedOrderList from "./pages/UnclaimedOrderList";
import Utilities from "./pages/Utilities";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import BackendGlobalsProvider from "./state/BackendGlobalsProvider";
import ErrorToastProvider from "./state/ErrorToastProvider";
import GlobalViewStateProvider from "./state/GlobalViewStateProvider";
import OfferingProvider from "./state/OfferingProvider";
import ScreenLoaderProvider from "./state/ScreenLoaderProvider";
import UserProvider from "./state/UserProvider";
import withLayout from "./state/withLayout";
import withMetatags from "./state/withMetatags";
import withProps from "./state/withProps";
import withScreenLoaderMount from "./state/withScreenLoaderMount";
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
                <RerenderOnLangChange>
                  <HelmetProvider>
                    <OfferingProvider>
                      <InnerApp />
                    </OfferingProvider>
                  </HelmetProvider>
                </RerenderOnLangChange>
              </ScreenLoaderProvider>
            </I18NextProvider>
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
  const { language } = useI18Next();
  return <React.Fragment key={language}>{children}</React.Fragment>;
}

function InnerApp() {
  const { i18nextLoading } = useI18Next();
  return i18nextLoading ? <ScreenLoader show /> : <AppRoutes />;
}

function AppRoutes() {
  return (
    <Router basename={import.meta.env.BASE_URL}>
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
            withProps({
              namespace: "terms_of_use_and_sale",
            }),
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
          path="/terms-of-sale-summer-2023"
          exact
          element={renderWithHocs(
            withProps({ namespace: "terms_of_sale_summer_2023" }),
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
          path="/contact-list"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles:contact_list"), exact: true }),
            withLayout({ nav: "none", bg: "bg-white" }),
            ContactListHome
          )}
        />
        <Route
          path="/contact-list/add"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles:contact_list_signup") }),
            withLayout({ gutters: true, top: true }),
            ContactListAdd
          )}
        />
        <Route
          path="/contact-list/success"
          exact
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles:contact_list_finish") }),
            withLayout({ gutters: true, top: true }),
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
          path="/product/:offeringId/:productId"
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
            withLayout({ gutters: false, top: true }),
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
            withMetatags({ title: t("titles:order_history") }),
            withLayout(),
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
            withMetatags({ title: t("food:unclaimed_order_history_title") }),
            withLayout(),
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
            withMetatags({ title: t("titles:order") }),
            withLayout(),
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
            withMetatags({ title: t("titles:private_accounts") }),
            withLayout(),
            PrivateAccountsList
          )}
        />
        <Route
          path="/preferences"
          exact
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles:preferences") }),
            withLayout({ top: true, gutters: true }),
            PreferencesAuthed
          )}
        />
        <Route
          path="/preferences-public"
          exact
          element={renderWithHocs(
            withScreenLoaderMount(),
            withMetatags({ title: t("titles:messaging_preferences") }),
            withLayout({ top: true, gutters: true }),
            PreferencesPublic
          )}
        />
        <Route
          path="/error"
          exact
          element={renderWithHocs(
            withMetatags({ title: t("common:error") }),
            withLayout(),
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
