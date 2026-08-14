import clsx from "clsx";
import React from "react";

interface LinearBreadcrumbsProps {
  /** Breadcrumb nav items. Each is in an li component. */
  items: React.ReactNode[];
  className?: string;
  /** If true, do not give the automatic mb-1. */
  noBottom?: boolean;
}

/**
 * Render items as list items in linear breadcrumb navigation.
 * See BackBreadcrumb for common usage.
 */
export default function LinearBreadcrumbs({
  items,
  className,
  noBottom,
}: LinearBreadcrumbsProps) {
  return (
    <nav className={clsx(noBottom || "mb-1", className)}>
      <ol className="linear-breadcrumb m-0">
        {items.map((it, i) => (
          <li key={i}>{it}</li>
        ))}
      </ol>
    </nav>
  );
}
