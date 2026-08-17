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
import withMetatags from "./hocs/withMetatags";
import withProps from "./hocs/withProps";
import withScreenLoaderMount from "./hocs/withScreenLoaderMount";
import { t } from "./localization";
import I18nProvider from "./localization/I18nProvider";
import useI18n from "./localization/useI18n";
import applyHocs from "./modules/applyHocs";
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
import OnboardingFinish from "./pages/onboarding/OnboardingFinish";
import OnboardingSignup from "./pages/onboarding/OnboardingSignup";
import OneTimePassword from "./pages/onboarding/OneTimePassword";
import Start from "./pages/onboarding/Start";
import BackendGlobalsProvider from "./state/BackendGlobalsProvider";
import GlobalViewStateProvider from "./state/GlobalViewStateProvider";
import OfferingProvider from "./state/OfferingProvider";
import ScreenLoaderProvider from "./state/ScreenLoaderProvider";
import UserProvider from "./state/UserProvider";
import Redirect from "./uir/Redirect";
import renderComponent from "./uir/renderComponent";
import React from "react";
import { HelmetProvider } from "react-helmet-async";
import { unstable_HistoryRouter as Router, Routes, Route } from "react-router-dom";

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
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("common.welcome_to_suma"), exact: true }),
            Home
          )}
        />
        <Route path="/privacy-policy" element={renderWithHocs(PrivacyPolicy)} />
        <Route
          path="/privacy-policy-content"
          element={renderWithHocs(PrivacyPolicyContent)}
        />
        <Route
          path="/terms-of-use"
          element={renderWithHocs(
            withProps({
              languageFile: "terms_of_use_and_sale",
            }),
            MarkdownContent
          )}
        />

        <Route
          path="/start"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.start") }),
            Start
          )}
        />
        <Route
          path="/regain-account-access"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("auth.access_account_title") }),
            RegainAccountAccess
          )}
        />
        <Route
          path="/regain-account-access/success"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("auth.access_account_title") }),
            withProps({ success: true }),
            RegainAccountAccess
          )}
        />
        <Route
          path="/one-time-password"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.otp") }),
            OneTimePassword
          )}
        />
        <Route
          path="/partner-signup"
          element={renderWithHocs(
            withMetatags({ title: t("titles.partner_signup") }),
            PartnerSignup
          )}
        />
        <Route
          path="/onboarding"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles.onboarding") }),

            Onboarding
          )}
        />
        <Route
          path="/onboarding/signup"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfBoarded,
            withMetatags({ title: t("titles.onboarding_signup") }),
            OnboardingSignup
          )}
        />
        <Route
          path="/onboarding/finish"
          element={renderWithHocs(
            redirectIfUnauthed,
            withMetatags({ title: t("titles.onboarding_finish") }),

            OnboardingFinish
          )}
        />
        <Route
          path="/contact-list"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list"), exact: true }),
            ContactListHome
          )}
        />
        <Route
          path="/contact-list/add"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list_signup") }),

            ContactListAdd
          )}
        />
        <Route
          path="/contact-list/success"
          element={renderWithHocs(
            redirectIfAuthed,
            withMetatags({ title: t("titles.contact_list_finish") }),
            ContactListSuccess
          )}
        />
        <Route
          path="/dashboard"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.dashboard") }),
            Dashboard
          )}
        />
        <Route
          path="/mobility"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("mobility.title") }),

            Mobility
          )}
        />
        <Route
          path="/food"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.title") }),
            Food
          )}
        />
        <Route
          path="/food/:id"
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
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.cart_title") }),
            FoodCart
          )}
        />
        <Route
          path="/checkout/:id"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.checkout") }),
            FoodCheckout
          )}
        />
        <Route
          path="/checkout/:id/confirmation"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.checkout") }),
            FoodCheckoutConfirmation
          )}
        />

        <Route
          path="/utilities"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("utilities.title") }),
            Utilities
          )}
        />
        <Route
          path="/funding"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.funding") }),
            Funding
          )}
        />
        <Route
          path="/link-bank-account"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("payments.link_bank_account") }),
            FundingLinkBankAccount
          )}
        />
        <Route
          path="/add-card"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("payments.add_card") }),
            FundingAddCard
          )}
        />
        <Route
          path="/add-funds"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("payments.add_funds") }),
            FundingAddFunds
          )}
        />
        <Route
          path="/ledgers"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.ledgers_overview") }),
            LedgersOverview
          )}
        />
        <Route
          path="/order-history"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.order_history") }),
            OrderHistoryList
          )}
        />
        <Route
          path="/unclaimed-orders"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("food.unclaimed_order_history_title") }),
            UnclaimedOrderList
          )}
        />
        <Route
          path="/order/:id"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.order") }),
            OrderHistoryDetail
          )}
        />
        <Route
          path="/private-accounts"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.private_accounts") }),
            PrivateAccountsList
          )}
        />
        <Route
          path="/private-account/:id"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.private_accounts") }),
            PrivateAccountDetail
          )}
        />
        <Route
          path="/trips"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.trips") }),
            Trips
          )}
        />
        <Route
          path="/trip/:id"
          element={renderWithHocs(
            redirectIfUnauthed,
            redirectIfUnboarded,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.trip_detail") }),
            TripDetail
          )}
        />
        <Route
          path="/preferences"
          element={renderWithHocs(
            redirectIfUnauthed,
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.preferences") }),
            PreferencesAuthed
          )}
        />
        <Route
          path="/preferences-public"
          element={renderWithHocs(
            withScreenLoaderMount(),
            withMetatags({ title: t("titles.messaging_preferences") }),
            PreferencesPublic
          )}
        />
        <Route
          path="/error"
          element={renderWithHocs(withMetatags({ title: t("common.error") }), () => (
            <LayoutContainer top>
              <ErrorScreen />
            </LayoutContainer>
          ))}
        />
        <Route path="/styleguide" element={<Styleguide />} />
        <Route path="/*" element={<Redirect to="/" />} />
      </Routes>
    </Router>
  );
}

function renderWithHocs(...args: Array<(x: any) => any>) {
  return renderComponent(applyHocs(...args));
}
