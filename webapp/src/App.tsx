import ErrorScreen from "./components/ErrorScreen";
import PrivacyPolicyContent from "./components/PrivacyPolicyContent";
import ScreenLoader from "./components/ScreenLoader";
import history from "./history";
import withProps from "./hocs/withProps";
import { t } from "./localization";
import I18nProvider from "./localization/I18nProvider";
import useI18n from "./localization/useI18n";
import { installPromiseExtras } from "./modules/bluejay";
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
import LedgersOverview from "./pages/LedgersOverview";
import MarkdownContent from "./pages/MarkdownContent";
import Mobility from "./pages/Mobility";
import OrderHistoryDetail from "./pages/OrderHistoryDetail";
import OrderHistoryList from "./pages/OrderHistoryList";
import PartnerSignup from "./pages/PartnerSignup";
import PreferencesAuthed from "./pages/PreferencesAuthed";
import PreferencesPublic from "./pages/PreferencesPublic";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import PrivateAccountDetail from "./pages/PrivateAccountDetail";
import PrivateAccountsList from "./pages/PrivateAccountsList";
import RegainAccountAccess from "./pages/RegainAccountAccess";
import Styleguide from "./pages/Styleguide";
import TripDetail from "./pages/TripDetail";
import Trips from "./pages/Trips";
import UnclaimedOrderList from "./pages/UnclaimedOrderList";
import Utilities from "./pages/Utilities";
import Home from "./pages/onboarding/Home";
import Onboarding from "./pages/onboarding/Onboarding";
import OnboardingAddress from "./pages/onboarding/OnboardingAddress.tsx";
import OnboardingEligibility from "./pages/onboarding/OnboardingEligibility.tsx";
import OnboardingName from "./pages/onboarding/OnboardingName.tsx";
import OnboardingOffers from "./pages/onboarding/OnboardingOffers.tsx";
import OnboardingTheme from "./pages/onboarding/OnboardingTheme.tsx";
import OneTimePassword from "./pages/onboarding/OneTimePassword";
import Start from "./pages/onboarding/Start";
import Redirect from "./routing/Redirect.tsx";
import Route from "./routing/Route";
import BackendGlobalsProvider from "./state/BackendGlobalsProvider";
import GlobalViewStateProvider from "./state/GlobalViewStateProvider";
import OfferingProvider from "./state/OfferingProvider";
import ScreenLoaderProvider from "./state/ScreenLoaderProvider";
import UserProvider from "./state/UserProvider";
import React from "react";
import { HelmetProvider } from "react-helmet-async";
import { unstable_HistoryRouter as Router, Routes } from "react-router-dom";

installPromiseExtras(window.Promise);

export default function App() {
  return (
    <GlobalViewStateProvider>
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
function RerenderOnLangChange({ children }: { children?: React.ReactNode }) {
  const { currentLanguage } = useI18n();
  return <React.Fragment key={currentLanguage}>{children}</React.Fragment>;
}

function InnerApp() {
  const { initializing } = useI18n();
  return initializing ? <ScreenLoader show /> : <AppRoutes />;
}

function AppRoutes() {
  return (
    <Router basename={import.meta.env.BASE_URL} history={history as any}>
      <Routes>
        <Route
          path="/"
          auth="unauthed"
          meta={{ title: t("common.welcome_to_suma"), exact: true }}
          Component={Home}
        />
        <Route path="/privacy-policy" Component={PrivacyPolicy} />
        <Route path="/privacy-policy-content" Component={PrivacyPolicyContent} />
        <Route
          path="/terms-of-use"
          hocs={[
            withProps({
              languageFile: "terms_of_use_and_sale",
            }),
          ]}
          Component={MarkdownContent}
        />

        <Route path="/start" meta="titles.start" auth="unauthed" Component={Start} />
        <Route
          path="/regain-account-access"
          auth="unauthed"
          meta="auth.access_account_title"
          Component={RegainAccountAccess}
        />
        <Route
          path="/regain-account-access/success"
          auth="unauthed"
          meta="auth.access_account_title"
          hocs={[withProps({ success: true })]}
          Component={RegainAccountAccess}
        />
        <Route
          path="/one-time-password"
          auth="unauthed"
          meta="titles.otp"
          Component={OneTimePassword}
        />
        <Route
          path="/partner-signup"
          meta="titles.partner_signup"
          Component={PartnerSignup}
        />
        <Route
          path="/onboarding"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={Onboarding}
        />
        <Route
          path="/onboarding/theme"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={OnboardingTheme}
        />
        <Route
          path="/onboarding/name"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={OnboardingName}
        />
        <Route
          path="/onboarding/address"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={OnboardingAddress}
        />
        <Route
          path="/onboarding/eligibility"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={OnboardingEligibility}
        />
        <Route
          path="/onboarding/offers"
          auth="require"
          onboarded="not"
          meta="titles.onboarding"
          Component={OnboardingOffers}
        />
        <Route
          path="/contact-list"
          auth="unauthed"
          meta={{ title: t("titles.contact_list"), exact: true }}
          Component={ContactListHome}
        />
        <Route
          path="/contact-list/add"
          auth="unauthed"
          meta="titles.contact_list_signup"
          Component={ContactListAdd}
        />
        <Route
          path="/contact-list/success"
          auth="unauthed"
          meta="titles.contact_list_finish"
          Component={ContactListSuccess}
        />
        <Route
          path="/dashboard"
          auth="require"
          onboarded="require"
          meta="titles.dashboard"
          screenLoader
          Component={Dashboard}
        />
        <Route
          path="/mobility"
          auth="require"
          onboarded="require"
          meta="mobility.title"
          screenLoader
          Component={Mobility}
        />
        <Route
          path="/food"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.title"
          Component={Food}
        />
        <Route
          path="/food/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.title"
          Component={FoodList}
        />
        <Route
          path="/product/:offeringId/:productId"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.title"
          Component={FoodDetails}
        />
        <Route
          path="/cart/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.cart_title"
          Component={FoodCart}
        />
        <Route
          path="/checkout/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.checkout"
          Component={FoodCheckout}
        />
        <Route
          path="/checkout/:id/confirmation"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.checkout"
          Component={FoodCheckoutConfirmation}
        />

        <Route
          path="/utilities"
          auth="require"
          onboarded="require"
          screenLoader
          meta="utilities.title"
          Component={Utilities}
        />
        <Route
          path="/funding"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.funding"
          Component={Funding}
        />
        <Route
          path="/link-bank-account"
          auth="require"
          onboarded="require"
          screenLoader
          meta="payments.link_bank_account"
          Component={FundingLinkBankAccount}
        />
        <Route
          path="/add-card"
          auth="require"
          onboarded="require"
          screenLoader
          meta="payments.add_card"
          Component={FundingAddCard}
        />
        <Route
          path="/add-funds"
          auth="require"
          onboarded="require"
          screenLoader
          meta="payments.add_funds"
          Component={FundingAddFunds}
        />
        <Route
          path="/ledgers"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.ledgers_overview"
          Component={LedgersOverview}
        />
        <Route
          path="/order-history"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.order_history"
          Component={OrderHistoryList}
        />
        <Route
          path="/unclaimed-orders"
          auth="require"
          onboarded="require"
          screenLoader
          meta="food.unclaimed_order_history_title"
          Component={UnclaimedOrderList}
        />
        <Route
          path="/order/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.order"
          Component={OrderHistoryDetail}
        />
        <Route
          path="/private-accounts"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.private_accounts"
          Component={PrivateAccountsList}
        />
        <Route
          path="/private-account/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.private_accounts"
          Component={PrivateAccountDetail}
        />
        <Route
          path="/trips"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.trips"
          Component={Trips}
        />
        <Route
          path="/trip/:id"
          auth="require"
          onboarded="require"
          screenLoader
          meta="titles.trip_detail"
          Component={TripDetail}
        />
        <Route
          path="/preferences"
          auth="require"
          screenLoader
          meta="titles.preferences"
          Component={PreferencesAuthed}
        />
        <Route
          path="/preferences-public"
          screenLoader
          meta="titles.messaging_preferences"
          Component={PreferencesPublic}
        />
        <Route path="/error" meta="common.error" Component={ErrorScreen} />
        <Route path="/styleguide" Component={Styleguide} />
        <Route path="/*" hocs={[withProps({ to: "/" })]} Component={Redirect} />
      </Routes>
    </Router>
  );
}
