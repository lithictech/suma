import Button from "../ui/Button";
import clsx from "clsx";
import React from "react";

interface NavButtonProps {
  /** Show the left chevron. */
  left?: boolean;
  /** Show the right chevron. */
  right?: boolean;
  className?: string;
  /** If null, use the 'short' logic (double chevron icons). */
  children?: React.ReactNode;
  [rest: string]: any;
}

/**
 * Render '< children' or 'children >' as a link button.
 */
export default function NavButton({
  left,
  right,
  className,
  children,
  ...rest
}: NavButtonProps) {
  const short = !children;
  const leftIcon = short ? "double-left" : "left";
  const rightIcon = short ? "double-right" : "right";
  return (
    <Button size="sm" variant="text" className={clsx("p-0", className)} {...rest}>
      {left && <i className={`bi bi-chevron-${leftIcon} me-1`} />}
      {children && <span>{children}</span>}
      {right && <i className={`bi bi-chevron-${rightIcon} ms-1`} />}
    </Button>
  );
}
