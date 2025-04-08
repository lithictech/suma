import useRoleAccess from "./useRoleAccess";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import AccountBalanceWalletIcon from "@mui/icons-material/AccountBalanceWallet";
import AddBusinessIcon from "@mui/icons-material/AddBusiness";
import AssignmentIndIcon from "@mui/icons-material/AssignmentInd";
import AutoModeIcon from "@mui/icons-material/AutoMode";
import BikeScooterIcon from "@mui/icons-material/BikeScooter";
import CorporateFareIcon from "@mui/icons-material/CorporateFare";
import EventAvailableIcon from "@mui/icons-material/EventAvailable";
import HomeIcon from "@mui/icons-material/Home";
import HowToRegIcon from "@mui/icons-material/HowToReg";
import KeyIcon from "@mui/icons-material/Key";
import MailIcon from "@mui/icons-material/Mail";
import ManageAccountsIcon from "@mui/icons-material/ManageAccounts";
import PaymentsIcon from "@mui/icons-material/Payments";
import PersonIcon from "@mui/icons-material/Person";
import PortraitIcon from "@mui/icons-material/Portrait";
import ReceiptIcon from "@mui/icons-material/Receipt";
import SellIcon from "@mui/icons-material/Sell";
import ShoppingBagIcon from "@mui/icons-material/ShoppingBag";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import StorefrontIcon from "@mui/icons-material/Storefront";
import TollIcon from "@mui/icons-material/Toll";
import React from "react";

/**
 * Calculate the nav items available to the current member,
 * based on roles.
 * Nav links is an array, where each item has:
 * - title, used as the list subheader, which can be empty.
 * - items, which always has at least one item.
 * @returns {({title: string, items: [{label: string, href: string, icon: JSX.Element}]})[]}
 */
export default function useNavLinks() {
  const { canRead } = useRoleAccess();
  const links = React.useMemo(() => {
    const members = canRead("admin_members");
    const payments = canRead("admin_payments");
    const commerce = canRead("admin_commerce");
    const management = canRead("admin_management");
    const r = [
      {
        title: "",
        items: [{ label: "Home", href: "/dashboard", icon: <HomeIcon /> }].filter(
          Boolean
        ),
      },
      {
        title: "Accounts",
        items: [
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
        ].filter(Boolean),
      },
      {
        title: "Payments",
        items: [
          payments && {
            label: "Ledgers",
            href: "/payment-ledgers",
            icon: <PaymentsIcon />,
          },
          payments && {
            label: "Charges",
            href: "/charges",
            icon: <ReceiptIcon />,
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
        ].filter(Boolean),
      },

      {
        title: "Commerce",
        items: [
          commerce && {
            label: "Offerings",
            href: "/offerings",
            icon: <ShoppingCartIcon />,
          },
          commerce && {
            label: "Products",
            href: "/products",
            icon: <SellIcon />,
          },
          commerce && {
            label: "Orders",
            href: "/orders",
            icon: <ShoppingBagIcon />,
          },
          management && {
            label: "Mobility Trips",
            href: "/mobility-trips",
            icon: <BikeScooterIcon />,
          },
        ].filter(Boolean),
      },
      {
        title: "Vendor Management",
        items: [
          commerce && {
            label: "Vendors",
            href: "/vendors",
            icon: <StorefrontIcon />,
          },
          commerce && {
            label: "External Accounts",
            href: "/vendor-accounts",
            icon: <PortraitIcon />,
          },
          commerce && {
            label: "External Account Configs",
            href: "/vendor-configurations",
            icon: <ManageAccountsIcon />,
          },
          commerce && {
            label: "Vendor Services",
            href: "/vendor-services",
            icon: <AddBusinessIcon />,
          },
        ].filter(Boolean),
      },
      {
        title: "Platform",
        items: [
          management && {
            label: "Programs",
            href: "/programs",
            icon: <EventAvailableIcon />,
          },
          management && {
            label: "Program Enrollments",
            href: "/program-enrollments",
            icon: <HowToRegIcon />,
          },
          members && {
            label: "Messages",
            href: "/messages",
            icon: <MailIcon />,
          },
          management && {
            label: "Roles",
            href: "/roles",
            icon: <KeyIcon />,
          },
        ].filter(Boolean),
      },
    ];
    return r.filter((t) => t.items.length > 0);
  }, [canRead]);
  return links;
}
