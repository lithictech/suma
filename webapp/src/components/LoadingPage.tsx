import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import Page from "../ui/Page.tsx";
import PageHeader, { PageHeaderProps } from "../ui/PageHeader.tsx";
import React from "react";

interface LoadingPageProps {
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
export default function LoadingPage({ page, header }: LoadingPageProps) {
  const loader = (
    <>
      {header}
      <IndeterminateLoader variant="plain" />
    </>
  );
  let content = loader;
  if (page) {
    content = <Page>{loader}</Page>;
  }
  return content;
}
