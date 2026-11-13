import { RoutePath } from "../routing/RoutePath.ts";
import "./Breadcrumb.css";
import Button, { ButtonProps } from "./Button.tsx";
import Icon from "./Icon.tsx";
import Stack from "./Stack.tsx";
import ChevronLeftIcon from "@heroicons/react/24/outline/ChevronLeftIcon";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import clsx from "clsx";

interface BreadcrumbProps {
  /**
   * Use it as the 'to' prop on the link.
   * If not provided, use history.back.
   */
  to?: RoutePath | null;
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  /** back shows a back button style; left and right are more subtle breadcrumbs. */
  variant?: "back" | "left" | "right";
  /**
   * Offset applies a negative margin to move the 'back' button so it is visually aligned
   * with text along vertical margins. For example, '< BACK'
   * stacked on a heading 'My Page' would not align visually (the chevron would be
   * about 6 pixels to the right of an alignment with the 'M' in 'My Page').
   * This negative margin moves the chevron to the left to achieve vertical alignment.
   */
  noOffset?: boolean;
  className?: string;
  /** If given, render this label. If not given, only a chevron is shown. */
  children?: React.ReactNode;
}

export default function Breadcrumb({
  to,
  variant = "back",
  noOffset,
  onClick,
  className,
  children,
}: BreadcrumbProps) {
  const backProps: ButtonProps = {};
  if (to) {
    backProps.to = to;
  } else {
    backProps.onClick = (e: React.MouseEvent<HTMLButtonElement>) => {
      e.preventDefault();
      window.history.back();
    };
  }
  if (onClick) {
    backProps.onClick = onClick;
  }
  const cls = clsx(
    "breadcrumb",
    `breadcrumb-${variant}`,
    children ? "breadcrumb-text" : "breadcrumb-empty",
    className
  );
  const left = variant !== "right";
  return (
    <div className="d-flex">
      <Button
        size="sm"
        variant="unstyled"
        className={cls}
        style={{
          marginLeft: noOffset ? "" : ICON_OFFSET,
          "--btn-color": "var(--text-secondary)",
          "--btn-bg": "var(--bg-card)",
          "--btn-border": `var(--border-secondary-subtle) var(--border-width) solid`,
        }}
        {...backProps}
      >
        <Stack row center>
          {left && (
            <Icon
              icon={ChevronLeftIcon}
              className={clsx("breadcrumb-icon-left", `breadcrumb-icon-${variant}`)}
            />
          )}
          {children && <span>{children}</span>}
          {!left && (
            <Icon
              icon={ChevronRightIcon}
              className={clsx("breadcrumb-icon-left", `breadcrumb-icon-${variant}`)}
            />
          )}
        </Stack>
      </Button>
    </div>
  );
}

const ICON_OFFSET = -6;
