import PageHeading from "../components/PageHeading";
import { t } from "../localization";
import useUser from "../state/useUser";
import React from "react";
import { Link } from "react-router-dom";

/**
 * Lists the main pages of the app in one place, as a second way to find them
 * besides the tab bar and the menu (WCAG 2.4.5 Multiple Ways).
 * Steps inside a process (sign in, onboarding, checkout) are left out.
 * Labels match the tab bar and menu so pages are named the same everywhere.
 * Linked from the footer of the main menu.
 */
export default function Sitemap() {
  const { user } = useUser();
  const sections = [
    {
      key: "sections",
      heading: t("sitemap.sections_heading"),
      links: [
        { to: "/dashboard", label: t("titles.home") },
        { to: "/mobility", label: t("titles.mobility") },
        { to: "/food", label: t("food.title") },
        { to: "/utilities", label: t("utilities.title") },
      ],
    },
    {
      key: "account",
      heading: t("sitemap.account_heading"),
      links: [
        user?.showPrivateAccounts && {
          to: "/private-accounts",
          label: t("titles.private_accounts"),
        },
        { to: "/funding", label: t("payments.payment_methods") },
        { to: "/ledgers", label: t("payments.ledger_transactions") },
        { to: "/order-history", label: t("titles.order_history") },
        { to: "/unclaimed-orders", label: t("food.unclaimed_order_history_title") },
        { to: "/trips", label: t("titles.trips") },
        { to: "/preferences", label: t("titles.preferences") },
      ].filter(Boolean),
    },
    {
      key: "about",
      heading: t("sitemap.about_heading"),
      links: [
        { to: "/terms-of-use", label: t("common.terms_of_use") },
        { to: "/privacy-policy", label: t("common.privacy_policy") },
        { to: "/glossary", label: t("glossary.title") },
      ],
    },
  ];
  return (
    <>
      <PageHeading>{t("sitemap.title")}</PageHeading>
      <p>{t("sitemap.intro")}</p>
      {sections.map(({ key, heading, links }) => (
        <section key={key} aria-labelledby={`sitemap-${key}`} className="mb-4">
          <h2 id={`sitemap-${key}`} className="h5">
            {heading}
          </h2>
          <ul>
            {links.map(({ to, label }) => (
              <li key={to} className="mb-2">
                <Link to={to}>{label}</Link>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </>
  );
}
