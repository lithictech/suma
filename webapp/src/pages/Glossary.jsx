import PageHeading from "../components/PageHeading.jsx";
import { t } from "../localization";
import React from "react";

/**
 * Explains words used in the app that members may not know
 * (WCAG 3.1.3 Unusual Words). Linked from the main menu on every page.
 */
export default function Glossary() {
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
            <dt id={`glossary-${key}`}>{term}</dt>
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
