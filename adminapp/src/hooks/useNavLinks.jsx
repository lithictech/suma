import useRoleAccess from "./useRoleAccess";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import AddBusinessIcon from "@mui/icons-material/AddBusiness";
import AssignmentIndIcon from "@mui/icons-material/AssignmentInd";
import AutoModeIcon from "@mui/icons-material/AutoMode";
import CorporateFareIcon from "@mui/icons-material/CorporateFare";
import HomeIcon from "@mui/icons-material/Home";
import KeyIcon from "@mui/icons-material/Key";
import ListAltIcon from "@mui/icons-material/ListAlt";
import MailIcon from "@mui/icons-material/Mail";
import ManageAccountsIcon from "@mui/icons-material/ManageAccounts";
import PaymentsIcon from "@mui/icons-material/Payments";
import PersonIcon from "@mui/icons-material/Person";
import PortraitIcon from "@mui/icons-material/Portrait";
import SellIcon from "@mui/icons-material/Sell";
import ShoppingBagIcon from "@mui/icons-material/ShoppingBag";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import StorefrontIcon from "@mui/icons-material/Storefront";
import TollIcon from "@mui/icons-material/Toll";
import React from "react";

export default function useNavLinks() {
  const { canRead } = useRoleAccess();
  const links = React.useMemo(() => {
    const members = canRead("admin_members");
    const payments = canRead("admin_payments");
    const commerce = canRead("admin_commerce");
    const management = canRead("admin_management");
    const r = [
      { label: "Home", href: "/dashboard", icon: <HomeIcon /> },
      members && { label: "Members", href: "/members", icon: <PersonIcon /> },
      members && {
        label: "Organizations",
        href: "/organizations",
        icon: <CorporateFareIcon />,
      },
      members && {
        label: "Organization Memberships",
        href: "/memberships",
        icon: <AssignmentIndIcon />,
      },
      payments && {
        label: "Ledgers",
        href: "/payment-ledgers",
        icon: <PaymentsIcon />,
      },
      payments && {
        label: "Book Transactions",
        href: "/book-transactions",
        icon: <AccountBalanceWalletIcon />,
      },
      payments && {
        label: "Funding Transactions",
        href: "/funding-transactions",
        icon: <AccountBalanceIcon />,
      },
      payments && {
        label: "Payout Transactions",
        href: "/payout-transactions",
        icon: <TollIcon />,
      },
      management && {
        label: "Payment Triggers",
        href: "/payment-triggers",
        icon: <AutoModeIcon />,
      },
      commerce && {
        label: "Vendors",
        href: "/vendors",
        icon: <StorefrontIcon />,
      },
      commerce && {
        label: "Products",
        href: "/products",
        icon: <SellIcon />,
      },
      commerce && {
        label: "Offerings",
        href: "/offerings",
        icon: <ShoppingCartIcon />,
      },
      commerce && {
        label: "Orders",
        href: "/orders",
        icon: <ShoppingBagIcon />,
      },
      commerce && {
        label: "Vendor Accounts",
        href: "/vendor-accounts",
        icon: <PortraitIcon />,
      },
      commerce && {
        label: "Vendor Configurations",
        href: "/vendor-configurations",
        icon: <ManageAccountsIcon />,
      },
      commerce && {
        label: "Vendor Services",
        href: "/vendor-services",
        icon: <AddBusinessIcon />,
      },
      commerce && {
        label: "Programs",
        href: "/programs",
        icon: <ListAltIcon />,
      },
      management && {
        label: "Program Enrollments",
        href: "/program-enrollments",
        icon: <ListAltIcon />,
      },
      management && {
        label: "Eligibility Constraints",
        href: "/constraints",
        icon: <KeyIcon />,
      },
      members && {
        label: "Messages",
        href: "/messages",
        icon: <MailIcon />,
      },
    ];
    return r.filter(Boolean);
  }, [canRead]);
  return links;
}
