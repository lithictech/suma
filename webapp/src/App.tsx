import ErrorPage from "./components/ErrorPage.tsx";
import ScreenLoader from "./components/ScreenLoader";
import history from "./history";
import { r } from "./localization";
import I18nProvider from "./localization/I18nProvider";
import useI18n from "./localization/useI18n";
import { installPromiseExtras } from "./modules/bluejay";
import ContactListAdd from "./pages/ContactListAdd";
import ContactListHome from "./pages/ContactListHome";
import ContactListSuccess from "./pages/ContactListSuccess";
import DashboardPage from "./pages/DashboardPage.tsx";
import Food from "./pages/Food";
import FoodCart from "./pages/FoodCart";
import FoodCheckout from "./pages/FoodCheckout";
import FoodCheckoutConfirmation from "./pages/FoodCheckoutConfirmation";
import FoodDetails from "./pages/FoodDetails";
import FoodList from "./pages/FoodList";
import FundingAddCard from "./pages/FundingAddCard";
import FundingLinkBankAccount from "./pages/FundingLinkBankAccount";
import FundingPage from "./pages/FundingPage.tsx";
import LedgersOverview from "./pages/LedgersOverview";
import MarkdownContent from "./pages/MarkdownContent";
import MenuPage from "./pages/MenuPage.tsx";
import Mobility from "./pages/Mobility";
import OrderHistoryDetail from "./pages/OrderHistoryDetail";
import OrderHistoryList from "./pages/OrderHistoryList";
import PartnerSignup from "./pages/PartnerSignup";
import PreferencesAuthed from "./pages/PreferencesAuthed";
import PreferencesPublic from "./pages/PreferencesPublic";
import PrivacyPolicyPage from "./pages/PrivacyPolicyPage.tsx";
import PrivateAccountDetail from "./pages/PrivateAccountDetail";
import PrivateAccountsList from "./pages/PrivateAccountsList";
import RegainAccountAccess from "./pages/RegainAccountAccess";
import ThemePage from "./pages/ThemePage.tsx";
import TripDetailPage from "./pages/TripDetailPage.tsx";
import Trips from "./pages/Trips";
import UnclaimedOrderList from "./pages/UnclaimedOrderList";
import Utilities from "./pages/Utilities";
import Home from "./pages/onboarding/Home";
import Onboarding from "./pages/onboarding/Onboarding";
import OneTimePassword from "./pages/onboarding/OneTimePassword";
import Start from "./pages/onboarding/Start";
import Redirect from "./routing/Redirect.tsx";
import typeRoute from "./routing/typeRoute.tsx";
import BackendGlobalsProvider from "./state/BackendGlobalsProvider";
import OfferingProvider from "./state/OfferingProvider";
import ScreenLoaderProvider from "./state/ScreenLoaderProvider";
import UserProvider from "./state/UserProvider";
import React from "react";
import { HelmetProvider } from "react-helmet-async";
import { unstable_HistoryRouter as Router, useRoutes } from "react-router-dom";

installPromiseExtras(window.Promise);

export default function App() {
  return (
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
  return initializing ? <ScreenLoader show /> : <AppRouter />;
}

function AppRouter() {
  return (
    <Router basename={import.meta.env.BASE_URL} history={history as any}>
      <AppRoutes />
    </Router>
  );
}

function AppRoutes() {
  const routes = [
    typeRoute({
      path: "/",
      auth: "unauthed",
      meta: { title: r("common.welcome_to_suma"), exact: true },
      Component: Home,
    }),
    typeRoute({ path: "/privacy-policy", Component: PrivacyPolicyPage }),
    typeRoute({
      path: "/privacy-policy-content",
      Component: PrivacyPolicyPage,
      pageProps: { contentOnly: true },
    }),
    typeRoute({
      path: "/terms-of-use",
      pageProps: {
        languageFile: "terms_of_use_and_sale",
      },
      Component: MarkdownContent,
    }),
    typeRoute({
      path: "/start",
      meta: "titles.start",
      auth: "unauthed",
      Component: Start,
    }),
    typeRoute({
      path: "/regain-account-access",
      auth: "unauthed",
      meta: "auth.access_account_title",
      Component: RegainAccountAccess,
    }),
    typeRoute({
      path: "/regain-account-access/success",
      auth: "unauthed",
      meta: "auth.access_account_title",
      pageProps: { success: true },
      Component: RegainAccountAccess,
    }),
    typeRoute({
      path: "/one-time-password",
      auth: "unauthed",
      meta: "titles.otp",
      Component: OneTimePassword,
    }),
    typeRoute({
      path: "/partner-signup",
      meta: "titles.partner_signup",
      Component: PartnerSignup,
    }),
    typeRoute({
      path: "/onboarding",
      auth: "require",
      meta: "titles.onboarding",
      Component: Onboarding,
    }),
    typeRoute({
      path: "/contact-list",
      auth: "unauthed",
      meta: { title: r("titles.contact_list"), exact: true },
      Component: ContactListHome,
    }),
    typeRoute({
      path: "/contact-list/add",
      auth: "unauthed",
      meta: "titles.contact_list_signup",
      Component: ContactListAdd,
    }),
    typeRoute({
      path: "/contact-list/success",
      auth: "unauthed",
      meta: "titles.contact_list_finish",
      Component: ContactListSuccess,
    }),
    typeRoute({
      path: "/dashboard",
      auth: "require",
      onboarded: "require",
      meta: "titles.dashboard",
      screenLoader: true,
      Component: DashboardPage,
    }),
    typeRoute({
      path: "/menu",
      auth: "require",
      onboarded: "require",
      meta: "titles.menu",
      Component: MenuPage,
    }),
    typeRoute({
      path: "/mobility",
      auth: "require",
      onboarded: "require",
      meta: "mobility.title",
      screenLoader: true,
      Component: Mobility,
    }),
    typeRoute({
      path: "/food",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.title",
      Component: Food,
    }),
    typeRoute({
      path: "/food/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.title",
      Component: FoodList,
    }),
    typeRoute({
      path: "/product/:offeringId/:productId",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.title",
      Component: FoodDetails,
    }),
    typeRoute({
      path: "/cart/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.cart_title",
      Component: FoodCart,
    }),
    typeRoute({
      path: "/checkout/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.checkout",
      Component: FoodCheckout,
    }),
    typeRoute({
      path: "/checkout/:id/confirmation",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.checkout",
      Component: FoodCheckoutConfirmation,
    }),

    typeRoute({
      path: "/utilities",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "utilities.title",
      Component: Utilities,
    }),
    typeRoute({
      path: "/funding",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.funding",
      Component: FundingPage,
    }),
    typeRoute({
      path: "/link-bank-account",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "payments.link_bank_account",
      Component: FundingLinkBankAccount,
    }),
    typeRoute({
      path: "/add-card",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "payments.add_card",
      Component: FundingAddCard,
    }),
    typeRoute({
      path: "/ledgers",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.ledgers_overview",
      Component: LedgersOverview,
    }),
    typeRoute({
      path: "/order-history",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.order_history",
      Component: OrderHistoryList,
    }),
    typeRoute({
      path: "/unclaimed-orders",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "food.unclaimed_order_history_title",
      Component: UnclaimedOrderList,
    }),
    typeRoute({
      path: "/order/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.order",
      Component: OrderHistoryDetail,
    }),
    typeRoute({
      path: "/private-accounts",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.private_accounts",
      Component: PrivateAccountsList,
    }),
    typeRoute({
      path: "/private-account/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.private_accounts",
      Component: PrivateAccountDetail,
    }),
    typeRoute({
      path: "/trips",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.trips",
      Component: Trips,
    }),
    typeRoute({
      path: "/trip/:id",
      auth: "require",
      onboarded: "require",
      screenLoader: true,
      meta: "titles.trip_detail",
      Component: TripDetailPage,
    }),
    typeRoute({
      path: "/preferences",
      auth: "require",
      screenLoader: true,
      meta: "titles.preferences",
      Component: PreferencesAuthed,
    }),
    typeRoute({
      path: "/preferences-public",
      screenLoader: true,
      meta: "titles.messaging_preferences",
      Component: PreferencesPublic,
    }),
    typeRoute({
      path: "/theme",
      meta: "titles.theme",
      Component: ThemePage,
    }),
    typeRoute({ path: "/error", meta: "common.error", Component: ErrorPage }),
    typeRoute({ path: "/*", pageProps: { to: "/" }, Component: Redirect }),
  ];
  const element = useRoutes(routes);
  return element;
}
