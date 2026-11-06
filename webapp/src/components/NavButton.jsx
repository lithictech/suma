import { t } from "../localization";
import RLink from "./RLink";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

/**
 * Render '< children' or 'children >' as a link button.
 * @param left Show the left chevron.
 * @param right Show the right chevron.
 * @param className
 * @param children If null, use the 'short' logic (double chevron icons).
 *   Since there is no visible text, an aria-label is added
 *   (defaulting to 'Back' for a left chevron, 'Next' for a right chevron).
 * @param rest Passed to the Button component.
 */
export default function NavButton({ left, right, className, children, ...rest }) {
  const short = !children;
  const leftIcon = short ? "double-left" : "left";
  const rightIcon = short ? "double-right" : "right";
  const shortLabel = left ? t("common.back") : t("common.next");
  return (
    <Button
      size="sm"
      as={RLink}
      variant="link"
      className={clsx("p-0", className)}
      aria-label={short ? shortLabel : undefined}
      // Chevron-only buttons must still be at least 24px wide (2.5.8 Target Size).
      style={short ? { minWidth: 24 } : undefined}
      {...rest}
    >
      {left && <i className={`bi bi-chevron-${leftIcon} me-1`} aria-hidden="true" />}
      {children && <span>{children}</span>}
      {right && <i className={`bi bi-chevron-${rightIcon} ms-1`} aria-hidden="true" />}
    </Button>
  );
}
