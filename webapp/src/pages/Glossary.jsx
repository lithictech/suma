import PageHeading from "../components/PageHeading.jsx";
import { t } from "../localization";
import React from "react";
import { useLocation } from "react-router-dom";

/**
 * Explains words used in the app that members may not know
 * (WCAG 3.1.3 Unusual Words). Linked from the main menu on every page.
 */
export default function Glossary() {
  const { hash } = useLocation();
  React.useEffect(() => {
    // Links like /glossary#glossary-ledger come from where the word is used (3.1.3):
    // scroll to the term and move focus to it so it is read out.
    if (!hash) {
      return;
    }
    // Wait a frame: PageLayout moves focus to <main> after navigating, and this runs after it.
    const frame = requestAnimationFrame(() => {
      const el = document.getElementById(decodeURIComponent(hash.slice(1)));
      if (el) {
        el.scrollIntoView({ block: "start" });
        el.focus({ preventScroll: true });
      }
    });
    return () => cancelAnimationFrame(frame);
  }, [hash]);
  const terms = TERM_KEYS.map((key) => ({
    key,
    term: t(`glossary.terms.${key}.term`),
    definition: t(`glossary.terms.${key}.definition`),
  }));
  // Order by the term in the current language, like a printed glossary.
  terms.sort((a, b) => String(a.term).localeCompare(String(b.term)));
  return (
    <>
      <PageHeading>{t("glossary.title")}</PageHeading>
      <p>{t("glossary.intro")}</p>
      <dl>
        {terms.map(({ key, term, definition }) => (
          <React.Fragment key={key}>
            <dt id={`glossary-${key}`} tabIndex={-1}>
              {term}
            </dt>
            <dd className="mb-3">{definition}</dd>
          </React.Fragment>
        ))}
      </dl>
    </>
  );
}

const TERM_KEYS = [
  "funding_source",
  "ledger",
  "micromobility",
  "offering",
  "private_account",
  "routing_number",
  "subsidy",
  "unclaimed_order",
  "vendor",
];
