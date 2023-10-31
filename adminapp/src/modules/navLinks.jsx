import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import HomeIcon from "@mui/icons-material/Home";
import KeyIcon from "@mui/icons-material/Key";
import MailIcon from "@mui/icons-material/Mail";
import PersonIcon from "@mui/icons-material/Person";
import SellIcon from "@mui/icons-material/Sell";
import ShoppingBagIcon from "@mui/icons-material/ShoppingBag";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import TollIcon from "@mui/icons-material/Toll";
import React from "react";

export default [
  { label: "Home", href: "/dashboard", icon: <HomeIcon /> },
  { label: "Members", href: "/members", icon: <PersonIcon /> },
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
    label: "Offerings",
    href: "/offerings",
    icon: <ShoppingCartIcon />,
  },
  {
    label: "Products",
    href: "/products",
    icon: <SellIcon />,
  },
  {
    label: "Eligibility Constraints",
    href: "/constraints",
    icon: <KeyIcon />,
  },
  {
    label: "Orders",
    href: "/orders",
    icon: <ShoppingBagIcon />,
  },
  {
    label: "Messages",
    href: "/messages",
    icon: <MailIcon />,
  },
];
