import { redirectIfAuthed, redirectIfUnauthed } from "./hocs/authRedirects";
import { UserProvider } from "./hooks/user";
import BankAccountDetailPage from "./pages/BankAccountDetailPage";
import BookTransactionCreatePage from "./pages/BookTransactionCreatePage";
import BookTransactionDetailPage from "./pages/BookTransactionDetailPage";
import BookTransactionListPage from "./pages/BookTransactionListPage";
import DashboardPage from "./pages/DashboardPage";
import EligibilityConstraintCreatePage from "./pages/EligibilityConstraintCreatePage";
import EligibilityConstraintDetailPage from "./pages/EligibilityConstraintDetailPage";
import EligibilityConstraintEditPage from "./pages/EligibilityConstraintEditPage";
import EligibilityConstraintListPage from "./pages/EligibilityConstraintListPage";
import FundingTransactionCreatePage from "./pages/FundingTransactionCreatePage";
import FundingTransactionDetailPage from "./pages/FundingTransactionDetailPage";
import FundingTransactionListPage from "./pages/FundingTransactionListPage";
import MemberDetailPage from "./pages/MemberDetailPage";
import MemberListPage from "./pages/MemberListPage";
import MessageDetailPage from "./pages/MessageDetailPage";
import MessageListPage from "./pages/MessageListPage";
import OfferingCreatePage from "./pages/OfferingCreatePage";
import OfferingDetailPage from "./pages/OfferingDetailPage";
import OfferingListPage from "./pages/OfferingListPage";
import OfferingPickListPage from "./pages/OfferingPickListPage";
import OfferingProductCreatePage from "./pages/OfferingProductCreatePage";
import OfferingProductDetailPage from "./pages/OfferingProductDetailPage";
import OrderDetailPage from "./pages/OrderDetailPage";
import OrderListPage from "./pages/OrderListPage";
import PayoutTransactionDetailPage from "./pages/PayoutTransactionDetailPage";
import PayoutTransactionListPage from "./pages/PayoutTransactionListPage";
import ProductCreatePage from "./pages/ProductCreatePage";
import ProductDetailPage from "./pages/ProductDetailPage";
import ProductEditPage from "./pages/ProductEditPage";
import ProductListPage from "./pages/ProductListPage";
import SignInPage from "./pages/SignInPage";
import VendorCreatePage from "./pages/VendorCreatePage";
import VendorDetailPage from "./pages/VendorDetailPage";
import VendorEditPage from "./pages/VendorEditPage";
import VendorListPage from "./pages/VendorListPage";
import applyHocs from "./shared/applyHocs";
import bluejay from "./shared/bluejay";
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

window.Promise = bluejay.Promise;

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <SnackbarProvider>
          <UserProvider>
            <Router basename={import.meta.env.BASE_URL}>
              <NavSwitch />
              <PageSwitch />
            </Router>
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
        path="/constraints"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          EligibilityConstraintListPage
        )}
      />
      <Route
        exact
        path="/constraint/new"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          EligibilityConstraintCreatePage
        )}
      />
      <Route
        exact
        path="/constraint/:id"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          EligibilityConstraintDetailPage
        )}
      />
      <Route
        exact
        path="/constraint/:id/edit"
        element={renderWithHocs(
          redirectIfUnauthed,
          withLayout(),
          EligibilityConstraintEditPage
        )}
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
        path="/offerings"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingListPage)}
      />
      <Route
        exact
        path="/offerings/new"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingCreatePage)}
      />
      <Route
        exact
        path="/offering/:id"
        element={renderWithHocs(redirectIfUnauthed, withLayout(), OfferingDetailPage)}
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
