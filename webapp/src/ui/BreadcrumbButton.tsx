import Button, { ButtonProps } from "../ui/Button";
import Icon from "./Icon.tsx";
import Stack from "./Stack.tsx";
import ChevroDoubleLeftIcon from "@heroicons/react/24/outline/ChevronDoubleLeftIcon";
import ChevronDoubleRightIcon from "@heroicons/react/24/outline/ChevronDoubleRightIcon";
import ChevronLeftIcon from "@heroicons/react/24/outline/ChevronLeftIcon";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import clsx from "clsx";
import React from "react";

interface BreadcrumbButtonProps extends ButtonProps {
  /** Show the left chevron. */
  left?: boolean;
  /** Show the right chevron. */
  right?: boolean;
  className?: string;
  /** If null, use the 'short' logic (double chevron icons). */
  children?: React.ReactNode;
}

/**
 * Render '< children' or 'children >' as a link button.
 */
export default function BreadcrumbButton({
  left,
  right,
  children,
  className,
  ...rest
}: BreadcrumbButtonProps) {
  const short = !children;
  const leftIcon = short ? ChevroDoubleLeftIcon : ChevronLeftIcon;
  const rightIcon = short ? ChevronDoubleRightIcon : ChevronRightIcon;
  const cls = clsx("px-0", left ? "pr-2" : "", right ? "pl-2" : "", className);
  return (
    <Button size="sm" variant="text" className={cls} {...rest}>
      <Stack row center>
        {left && <Icon icon={leftIcon} className="mr-1" />}
        {children && <span>{children}</span>}
        {right && <Icon icon={rightIcon} className="ml-1" />}
      </Stack>
    </Button>
  );
}
