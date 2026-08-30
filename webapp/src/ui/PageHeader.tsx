import { RoutePath } from "../routing/RoutePath.ts";
import BreadcrumbBack from "./BreadcrumbBack.tsx";
import "./PageHeader.css";
import React from "react";

export interface PageHeaderProps {
  /** The text of the title. */
  title: React.ReactNode;
  /** The text under the title. */
  subtitle?: React.ReactNode;
  /** Primary uses primary color text.
   * Secondary doesn't use special colors.
   * Default is primary is there is no back,
   * and secondary if there is.
   */
  variant?: "default" | "primary" | "secondary";
  /** Whether to show the back breadcrumb. */
  back?: boolean | RoutePath;
}

/**
 * Header for the top of the page.
 */
export default function PageHeader({
  title,
  subtitle,
  variant = "default",
  back,
}: PageHeaderProps) {
  if (variant === "default") {
    variant = back ? "secondary" : "primary";
  }
  return (
    <>
      {back && <BreadcrumbBack back={back} />}
      <h2 className={`page-header-${variant}`}>{title}</h2>
      {subtitle && <p className="page-header-subtitle">{subtitle}</p>}
    </>
  );
}
