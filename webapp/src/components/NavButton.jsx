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
 * @param rest Passed to the Button component.
 */
export default function NavButton({ left, right, className, children, ...rest }) {
  const short = !children;
  const leftIcon = short ? "double-left" : "left";
  const rightIcon = short ? "double-right" : "right";
  return (
    <Button
      size="sm"
      as={RLink}
      variant="link"
      className={clsx("p-0", className)}
      {...rest}
    >
      {left && <i className={`bi bi-chevron-${leftIcon} me-1`} />}
      {children && <span>{children}</span>}
      {right && <i className={`bi bi-chevron-${rightIcon} ms-1`} />}
    </Button>
  );
}
