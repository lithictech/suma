import "../assets/styles/screenloader.scss";
import { t } from "../localization";
import React from "react";
import { Helmet } from "react-helmet-async";

/**
 * @param {string=} title Page title.
 * @param {boolean=} exact If true, use the title as-is.
 * @param {string|string[]=} section Section(s) the page sits inside, from nearest to top-level,
 *   added after the title so the page title shows where the member is (2.4.8).
 */
export default function withMetatags({ title, exact, section }) {
  const parts = [title, ...[section || []].flat(), t("titles.suma_app")].filter(Boolean);
  const customTitle = parts.join(" | ");
  return (Wrapped) => {
    return (props) => {
      return (
        <>
          <Helmet>
            <title>{exact ? title : customTitle}</title>
          </Helmet>
          <Wrapped {...props} />
        </>
      );
    };
  };
}
