import { t } from "../localization";
import Button from "../ui/Button.tsx";
import Page from "../ui/Page.tsx";
import PageHeader, { PageHeaderProps } from "../ui/PageHeader.tsx";
import Stack from "../ui/Stack.tsx";
import GoHome from "./GoHome";
import React from "react";

interface ErrorPageProps {
  title?: React.ReactNode;
  body?: React.ReactNode;
  /** Provides a 'Go Home' button in the 'home' variant, or a 'Back' button in the back variant. */
  variant: "back" | "home";
  /**
   * If true, wrap the error in a Page element, so it can stand alone.
   * Set to false when nested within an existing Page.
   */
  page: boolean;
  /** If given, render the page header element. Should set page to true. */
  header?: React.ReactElement<PageHeaderProps, typeof PageHeader>;
}

/**
 * Show this component when an unhandled error has occurred.
 */
export default function ErrorPage({
  title,
  body,
  variant,
  page,
  header,
}: ErrorPageProps) {
  let action: React.ReactElement;
  if (variant === "back") {
    action = (
      <Button size="lg" onClick={window.history.back}>
        {t("common.back")}
      </Button>
    );
  } else {
    console.assert(variant === "home");
    action = <GoHome />;
  }
  let content = (
    <>
      {header}
      <Stack col gap={5} className="text-center">
        <h2>{title || t("errors.something_went_wrong_title")}</h2>
        <p>{body || t("errors.something_went_wrong_body")}</p>
        {action}
      </Stack>
    </>
  );
  if (page) {
    content = <Page>{content}</Page>;
  }
  return content;
}
