import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import AssignmentIndIcon from "@mui/icons-material/AssignmentInd";
import AutoModeIcon from "@mui/icons-material/AutoMode";
import CorporateFareIcon from "@mui/icons-material/CorporateFare";
import HomeIcon from "@mui/icons-material/Home";
import KeyIcon from "@mui/icons-material/Key";
import MailIcon from "@mui/icons-material/Mail";
import ManageAccountsIcon from "@mui/icons-material/ManageAccounts";
import PaymentsIcon from '@mui/icons-material/Payments';
import PersonIcon from "@mui/icons-material/Person";
import PortraitIcon from "@mui/icons-material/Portrait";
import SellIcon from "@mui/icons-material/Sell";
import ShoppingBagIcon from "@mui/icons-material/ShoppingBag";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import StorefrontIcon from "@mui/icons-material/Storefront";
import TollIcon from "@mui/icons-material/Toll";
import React from "react";

export default [
  { label: "Home", href: "/dashboard", icon: <HomeIcon /> },
  { label: "Members", href: "/members", icon: <PersonIcon /> },
  { label: "Organizations", href: "/organizations", icon: <CorporateFareIcon /> },
  {
    label: "Organization Memberships",
    href: "/memberships",
    icon: <AssignmentIndIcon />,
  },
  {
    label: "Platform Ledgers",
    href: "/platform-ledgers",
    icon: <PaymentsIcon />,
  },
  {
    label: "Book Transactions",
    href: "/book-transactions",
    icon: <AccountBalanceWalletIcon />,
  },
  {
    label: "Funding Transactions",
    href: "/funding-transactions",
    icon: <AccountBalanceIcon />,
  },
  {
    label: "Payout Transactions",
    href: "/payout-transactions",
    icon: <TollIcon />,
  },
  {
    label: "Payment Triggers",
    href: "/payment-triggers",
    icon: <AutoModeIcon />,
  },
  {
    label: "Vendors",
    href: "/vendors",
    icon: <StorefrontIcon />,
  },
  {
    label: "Products",
    href: "/products",
    icon: <SellIcon />,
  },
  {
    label: "Offerings",
    href: "/offerings",
    icon: <ShoppingCartIcon />,
  },
  {
    label: "Orders",
    href: "/orders",
    icon: <ShoppingBagIcon />,
  },
  {
    label: "Vendor Accounts",
    href: "/vendor-accounts",
    icon: <PortraitIcon />,
  },
  {
    label: "Vendor Configurations",
    href: "/vendor-configurations",
    icon: <ManageAccountsIcon />,
  },
  {
    label: "Eligibility Constraints",
    href: "/constraints",
    icon: <KeyIcon />,
  },
  {
    label: "Messages",
    href: "/messages",
    icon: <MailIcon />,
  },
];
