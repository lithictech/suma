import { t } from "../localization";
import GoHome from "./GoHome";
import React from "react";

/**
 * Show this component when an unhandled error has occurred.
 * Provides a 'Go Home' button.
 * @returns {JSX.Element}
 * @constructor
 */
export default function ErrorScreen({ title, body, actionLabel, actionHref }) {
  return (
    <>
      <h2>{title || t("errors.something_went_wrong_title")}</h2>
      <p>{body || t("errors.something_went_wrong_body")}</p>
      <GoHome href={actionHref} label={actionLabel} />
    </>
  );
}
