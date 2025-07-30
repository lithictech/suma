import clsx from "clsx";
import React from "react";

/**
 * Render items as list items in linear breadcrumb navigation.
 * See BackBreadcrumb for common usage.
 * @param items Breadcrumb nav items. Each is in an li component.
 * @param className
 * @param noBottom If true, do not give the automatic mb-1.
 */
export default function LinearBreadcrumbs({ items, className, noBottom }) {
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
