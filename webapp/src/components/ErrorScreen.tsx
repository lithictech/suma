import { t } from "../localization";
import GoHome from "./GoHome";
import React from "react";

interface ErrorScreenProps {
  title?: React.ReactNode;
  body?: React.ReactNode;
  actionLabel?: React.ReactNode;
  actionHref?: string;
}

/**
 * Show this component when an unhandled error has occurred.
 * Provides a 'Go Home' button.
 */
export default function ErrorScreen({
  title,
  body,
  actionLabel,
  actionHref,
}: ErrorScreenProps) {
  return (
    <>
      <h2>{title || t("errors.something_went_wrong_title")}</h2>
      <p>{body || t("errors.something_went_wrong_body")}</p>
      <GoHome href={actionHref} label={actionLabel} />
    </>
  );
}
