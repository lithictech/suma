import GoHome from "./GoHome";
import TopNav from "./TopNav";
import i18next from "i18next";
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
    <div className="main-container">
      <TopNav />
      <Container>
        <h2>{i18next.t("something_went_wrong_title", { ns: "errors" })}</h2>
        <p>{i18next.t("something_went_wrong_body", { ns: "errors" })}</p>
        <GoHome />
      </Container>
    </div>
  );
}
