import { t } from "../localization";
import LinearBreadcrumbs from "./LinearBreadcrumbs";
import NavButton from "./NavButton";
import React from "react";

interface BackBreadcrumbProps {
  /** If true, use window.history.back. Otherwise, use it as the 'to' prop on the link. */
  back?: boolean | string;
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
export default function BackBreadcrumb({ back, children, ...rest }: BackBreadcrumbProps) {
  let backProps;
  if (back === true) {
    backProps = {
      to: "#",
      onClick: (e) => {
        e.preventDefault();
        window.history.back();
      },
    };
  } else {
    backProps = { to: back };
  }
  const short = !!children;
  return (
    <LinearBreadcrumbs
      items={[
        <NavButton
          key="back"
          left
          size="sm"
          style={{ marginLeft: ICON_OFFSET }}
          className={short && "link-unstyled"}
          {...backProps}
        >
          {short ? null : t("common.back")}
        </NavButton>,
        <React.Fragment key="child">{children}</React.Fragment>,
      ]}
      {...rest}
    />
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
