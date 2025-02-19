import { redirectIfAuthed, redirectIfUnauthed } from "./hocs/authRedirects";
import { GlobalApiStateProvider } from "./hooks/globalApiState";
import { UserProvider } from "./hooks/user";
import BankAccountDetailPage from "./pages/BankAccountDetailPage";
import BookTransactionCreatePage from "./pages/BookTransactionCreatePage";
import BookTransactionDetailPage from "./pages/BookTransactionDetailPage";
import BookTransactionListPage from "./pages/BookTransactionListPage";
import DashboardPage from "./pages/DashboardPage";
import FundingTransactionCreatePage from "./pages/FundingTransactionCreatePage";
import FundingTransactionDetailPage from "./pages/FundingTransactionDetailPage";
import FundingTransactionListPage from "./pages/FundingTransactionListPage";
import MemberDetailPage from "./pages/MemberDetailPage";
import MemberEditPage from "./pages/MemberEditPage";
import MemberListPage from "./pages/MemberListPage";
import MessageDetailPage from "./pages/MessageDetailPage";
import MessageListPage from "./pages/MessageListPage";
import MobilityTripDetailPage from "./pages/MobilityTripDetailPage";
import MobilityTripEditPage from "./pages/MobilityTripEditPage";
import MobilityTripListPage from "./pages/MobilityTripListPage";
import OfferingCreatePage from "./pages/OfferingCreatePage";
import OfferingDetailPage from "./pages/OfferingDetailPage";
import OfferingEditPage from "./pages/OfferingEditPage";
import OfferingListPage from "./pages/OfferingListPage";
import OfferingPickListPage from "./pages/OfferingPickListPage";
import OfferingProductCreatePage from "./pages/OfferingProductCreatePage";
import OfferingProductDetailPage from "./pages/OfferingProductDetailPage";
import OfferingProductEditPage from "./pages/OfferingProductEditPage";
import OrderDetailPage from "./pages/OrderDetailPage";
import OrderListPage from "./pages/OrderListPage";
import OrganizationCreatePage from "./pages/OrganizationCreatePage";
import OrganizationDetailPage from "./pages/OrganizationDetailPage";
import OrganizationEditPage from "./pages/OrganizationEditPage";
import OrganizationListPage from "./pages/OrganizationListPage";
import OrganizationMembershipCreatePage from "./pages/OrganizationMembershipCreatePage";
import OrganizationMembershipDetailPage from "./pages/OrganizationMembershipDetailPage";
import OrganizationMembershipEditPage from "./pages/OrganizationMembershipEditPage";
import OrganizationMembershipListPage from "./pages/OrganizationMembershipListPage";
import PaymentLedgerDetailPage from "./pages/PaymentLedgerDetailPage";
import PaymentLedgerListPage from "./pages/PaymentLedgerListPage";
import PaymentTriggerCreatePage from "./pages/PaymentTriggerCreatePage";
import PaymentTriggerDetailPage from "./pages/PaymentTriggerDetailPage";
import PaymentTriggerEditPage from "./pages/PaymentTriggerEditPage";
import PaymentTriggerListPage from "./pages/PaymentTriggerListPage";
import PayoutTransactionDetailPage from "./pages/PayoutTransactionDetailPage";
import PayoutTransactionListPage from "./pages/PayoutTransactionListPage";
import ProductCreatePage from "./pages/ProductCreatePage";
import ProductDetailPage from "./pages/ProductDetailPage";
import ProductEditPage from "./pages/ProductEditPage";
import ProductListPage from "./pages/ProductListPage";
import ProgramCreatePage from "./pages/ProgramCreatePage";
import ProgramDetailPage from "./pages/ProgramDetailPage";
import ProgramEditPage from "./pages/ProgramEditPage";
import ProgramEnrollmentCreatePage from "./pages/ProgramEnrollmentCreatePage";
import ProgramEnrollmentDetailPage from "./pages/ProgramEnrollmentDetailPage";
import ProgramEnrollmentListPage from "./pages/ProgramEnrollmentListPage";
import ProgramListPage from "./pages/ProgramListPage";
import SignInPage from "./pages/SignInPage";
import VendorAccountDetailPage from "./pages/VendorAccountDetailPage";
import VendorAccountListPage from "./pages/VendorAccountListPage";
import VendorConfigurationDetailPage from "./pages/VendorConfigurationDetailPage";
import VendorConfigurationListPage from "./pages/VendorConfigurationListPage";
import VendorCreatePage from "./pages/VendorCreatePage";
import VendorDetailPage from "./pages/VendorDetailPage";
import VendorEditPage from "./pages/VendorEditPage";
import VendorListPage from "./pages/VendorListPage";
import VendorServiceDetailPage from "./pages/VendorServiceDetailPage";
import VendorServiceEditPage from "./pages/VendorServiceEditPage";
import VendorServiceListPage from "./pages/VendorServiceListPage";
import applyHocs from "./shared/applyHocs";
import { installPromiseExtras } from "./shared/bluejay";
import ClientsideSearchParamsProvider from "./shared/react/ClientsideSearchParamsProvider";
import Redirect from "./shared/react/Redirect";
import renderComponent from "./shared/react/renderComponent";
import withLayout from "./state/withLayout";
import theme from "./theme";
import { ThemeProvider } from "@mui/material";
import { LocalizationProvider } from "@mui/x-date-pickers";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import { SnackbarProvider } from "notistack";
import React from "react";
import { Route, BrowserRouter as Router, Routes } from "react-router-dom";

installPromiseExtras(window.Promise);

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <SnackbarProvider>
          <UserProvider>
            <GlobalApiStateProvider>
              <Router basename={import.meta.env.BASE_URL}>
                <ClientsideSearchParamsProvider>
                  <NavSwitch />
                  <PageSwitch />
                </ClientsideSearchParamsProvider>
              </Router>
            </GlobalApiStateProvider>
          </UserProvider>
        </SnackbarProvider>
      </LocalizationProvider>
    </ThemeProvider>
  );
}

function NavSwitch() {
  return (
    <Routes>
      <Route exact path="/" element={null} />
      <Route exact path="/sign-in" element={null} />
      <Route exact path="/*" element={null} />
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
        element={renderWithHocs(redirectIfUnauthed, withLayout(), DashboardPage)}
      />
      <Route
        exact
        path="/bank-account/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), BankAccountDetailPage)}
      />
      <Route
        exact
        path="/funding-transactions"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          FundingTransactionListPage
        )}
      />
      <Route
        exact
        path="/funding-transaction/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          FundingTransactionCreatePage
        )}
      />
      <Route
        exact
        path="/funding-transaction/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          FundingTransactionDetailPage
        )}
      />
      <Route
        exact
        path="/payout-transactions"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          PayoutTransactionListPage
        )}
      />
      <Route
        exact
        path="/payout-transaction/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          PayoutTransactionDetailPage
        )}
      />
      <Route
        exact
        path="/book-transactions"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          BookTransactionListPage
        )}
      />
      <Route
        exact
        path="/book-transaction/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          BookTransactionCreatePage
        )}
      />
      <Route
        exact
        path="/book-transaction/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          BookTransactionDetailPage
        )}
      />
      <Route
        exact
        path="/payment-triggers"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), PaymentTriggerListPage)}
      />
      <Route
        exact
        path="/payment-trigger/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          PaymentTriggerCreatePage
        )}
      />
      <Route
        exact
        path="/payment-trigger/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          PaymentTriggerDetailPage
        )}
      />
      <Route
        exact
        path="/payment-trigger/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), PaymentTriggerEditPage)}
      />
      <Route
        exact
        path="/payment-ledgers"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), PaymentLedgerListPage)}
      />
      <Route
        exact
        path="/payment-ledger/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          PaymentLedgerDetailPage
        )}
      />
      <Route
        exact
        path="/mobility-trips"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MobilityTripListPage)}
      />
      <Route
        exact
        path="/mobility-trip/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MobilityTripDetailPage)}
      />
      <Route
        exact
        path="/mobility-trip/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MobilityTripEditPage)}
      />

      <Route
        exact
        path="/offerings"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingListPage)}
      />
      <Route
        exact
        path="/offering/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingCreatePage)}
      />
      <Route
        exact
        path="/offering/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingDetailPage)}
      />
      <Route
        exact
        path="/offering/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingEditPage)}
      />
      <Route
        exact
        path="/offering/:id/picklist"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingPickListPage)}
      />
      <Route
        exact
        path="/products"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProductListPage)}
      />
      <Route
        exact
        path="/product/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProductCreatePage)}
      />
      <Route
        exact
        path="/product/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProductDetailPage)}
      />
      <Route
        exact
        path="/product/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProductEditPage)}
      />
      <Route
        exact
        path="/offering-product/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OfferingProductCreatePage
        )}
      />
      <Route
        exact
        path="/offering-product/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OfferingProductDetailPage
        )}
      />
      <Route
        exact
        path="/offering-product/:id/edit"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OfferingProductEditPage
        )}
      />
      <Route
        exact
        path="/vendors"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorListPage)}
      />
      <Route
        exact
        path="/vendor/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorCreatePage)}
      />
      <Route
        exact
        path="/vendor/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorDetailPage)}
      />
      <Route
        exact
        path="/vendor/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorEditPage)}
      />
      <Route
        exact
        path="/programs"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProgramListPage)}
      />
      <Route
        exact
        path="/program/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProgramCreatePage)}
      />
      <Route
        exact
        path="/program/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProgramDetailPage)}
      />
      <Route
        exact
        path="/program/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), ProgramEditPage)}
      />
      <Route
        exact
        path="/program-enrollments"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          ProgramEnrollmentListPage
        )}
      />
      <Route
        exact
        path="/program-enrollment/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          ProgramEnrollmentCreatePage
        )}
      />
      <Route
        exact
        path="/program-enrollment/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          ProgramEnrollmentDetailPage
        )}
      />
      <Route
        exact
        path="/vendor-accounts"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorAccountListPage)}
      />
      <Route
        exact
        path="/vendor-account/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          VendorAccountDetailPage
        )}
      />
      <Route
        exact
        path="/vendor-configurations"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          VendorConfigurationListPage
        )}
      />
      <Route
        exact
        path="/vendor-configuration/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          VendorConfigurationDetailPage
        )}
      />
      <Route
        exact
        path="/vendor-services"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorServiceListPage)}
      />
      <Route
        exact
        path="/vendor-service/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          VendorServiceDetailPage
        )}
      />
      <Route
        exact
        path="/vendor-service/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), VendorServiceEditPage)}
      />
      <Route
        exact
        path="/orders"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrderListPage)}
      />
      <Route
        exact
        path="/order/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrderDetailPage)}
      />
      <Route
        exact
        path="/members"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MemberListPage)}
      />
      <Route
        exact
        path="/member/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MemberDetailPage)}
      />
      <Route
        exact
        path="/member/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MemberEditPage)}
      />
      <Route
        exact
        path="/organizations"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrganizationListPage)}
      />
      <Route
        exact
        path="/organization/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrganizationDetailPage)}
      />
      <Route
        exact
        path="/organization/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrganizationCreatePage)}
      />
      <Route
        exact
        path="/organization/:id/edit"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OrganizationEditPage)}
      />
      <Route
        exact
        path="/memberships"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OrganizationMembershipListPage
        )}
      />
      <Route
        exact
        path="/membership/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OrganizationMembershipDetailPage
        )}
      />
      <Route
        exact
        path="/membership/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OrganizationMembershipCreatePage
        )}
      />
      <Route
        exact
        path="/membership/:id/edit"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          OrganizationMembershipEditPage
        )}
      />
      <Route
        exact
        path="/messages"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MessageListPage)}
      />
      <Route
        exact
        path="/message/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), MessageDetailPage)}
      />
      <Route
        path="/*"
        element={renderWithHocs(
          redirectIfAuthed,
          withLayout(),
          redirectIfUnauthed,
          () => (
            <Redirect to="/" />
          )
        )}
      />
    </Routes>
  );
}

function renderWithHocs(...args) {
  return renderComponent(applyHocs(...args));
}
