import { t } from "../localization";
import GoHome from "./GoHome";
import TopNav from "./TopNav";
import React from "react";
import Container from "react-bootstrap/Container";

/**
 * Show this component when an unhandled error has occurred.
 * Provides a 'Go Home' button.
 * @returns {JSX.Element}
 * @constructor
 */
export default function ErrorScreen() {
  return (
    <>
      <h2>{t("errors:something_went_wrong_title")}</h2>
      <p>{t("errors:something_went_wrong_body")}</p>
      <GoHome />
    </>
  );
}
