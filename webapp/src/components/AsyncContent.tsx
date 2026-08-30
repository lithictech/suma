import { AppError } from "../modules/feedback.ts";
import ErrorPage from "./ErrorPage.tsx";
import LoadingPage from "./LoadingPage.tsx";
import React from "react";

interface AsyncContentProps {
  loading: boolean;
  error: AppError | null | undefined;
  children: () => React.ReactElement;
}

/**
 * Show a loader, error, or the children, depending on inputs.
 */
export default function AsyncContent({ loading, error, children }: AsyncContentProps) {
  if (loading) {
    return <LoadingPage page={false} />;
  }
  if (error) {
    return <ErrorPage variant="back" page={false} />;
  }
  return children();
}
