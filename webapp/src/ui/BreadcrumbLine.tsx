import React from "react";

interface BreadcrumbLineProps {
  /** Breadcrumb nav items. Each is in an li component. */
  items: React.ReactNode[];
  className?: string;
}

/**
 * Render items as list items in linear breadcrumb navigation.
 * See BreadcrumbBack for common usage.
 */
export default function BreadcrumbLine({ items, className }: BreadcrumbLineProps) {
  return (
    <nav className={className}>
      <ol className="linear-breadcrumb m-0">
        {items.map((it, i) => (
          <li key={i}>{it}</li>
        ))}
      </ol>
    </nav>
  );
}
