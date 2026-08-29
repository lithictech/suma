import { t } from "../localization";
import { RoutePath } from "../routing/RoutePath.ts";
import BreadcrumbButton from "./BreadcrumbButton.tsx";
import { ButtonProps } from "./Button.tsx";
import React from "react";

interface BreadcrumbBackProps {
  /** If true, use window.history.back. Otherwise, use it as the 'to' prop on the link. */
  back: true | RoutePath;
  /**
   * Additional nav item (usually a title/heading).
   * If children is present, do not render the text 'Back'; use a short variant,
   * with just a double chevron as the back link (and render it with unstyled color
   * to improve contrast).
   */
  children?: React.ReactNode;
  /** Passed to LinearBreadcrumbs. */
  [rest: string]: any;
}

/**
 * Simplified form of LinearBreadcrumb that renders a single 'Back' NavButton.
 */
export default function BreadcrumbBack({ back, children }: BreadcrumbBackProps) {
  const backProps: ButtonProps = { variant: "text" };
  if (back === true) {
    backProps.onClick = (e: React.MouseEvent<HTMLButtonElement>) => {
      e.preventDefault();
      window.history.back();
    };
  } else {
    backProps.to = back;
  }
  const short = !!children;
  return (
    <div className="d-flex">
      <BreadcrumbButton
        key="back"
        left
        size="sm"
        style={{ marginLeft: ICON_OFFSET }}
        {...backProps}
      >
        {short ? null : t("common.back")}
      </BreadcrumbButton>
    </div>
  );
}

/**
 * Apply a negative margin to move the 'back' button so it is visually aligned
 * with text along vertical margins. For example, '< BACK'
 * stacked on a heading 'My Page' would not align visually (the chevron would be
 * about 6 pixels to the right of an alignment with the 'M' in 'My Page').
 * This negative margin moves the chevron to the left to achieve vertical alignment.
 */
const ICON_OFFSET = -6;
