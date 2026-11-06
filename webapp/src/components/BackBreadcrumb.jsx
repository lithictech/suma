import { t } from "../localization";
import LinearBreadcrumbs from "./LinearBreadcrumbs.jsx";
import NavButton from "./NavButton";
import React from "react";

/**
 * Simplified form of LinearBreadcrumb that renders a single 'Back' NavButton.
 * @param {boolean|string} back If true, use window.history.back.
 *   Otherwise, use it as the 'to' prop on the link.
 * @param children Additional nav item (usually a title/heading).
 *   If children is present, do not render the text 'Back'; use a short variant,
 *   with just a double chevron as the back link (and render it with unstyled color
 *   to improve contrast).
 * @param rest Passed to LinearBreadcrumbs.
 */
export default function BackBreadcrumb({ back, children, ...rest }) {
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
  // The link name says where it goes (2.4.9), and starts with the visible "Back".
  const page = back === true ? null : backTargetLabel(back);
  const backName = page ? t("common.back_to", { page }) : t("common.back_previous");
  return (
    <LinearBreadcrumbs
      items={[
        <NavButton
          key="back"
          left
          size="sm"
          style={{ marginLeft: ICON_OFFSET }}
          className={short && "link-unstyled"}
          aria-label={backName}
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
 * Name of the page a 'back' path leads to, or null if it is not a known section page.
 */
function backTargetLabel(to) {
  if (typeof to !== "string") {
    return null;
  }
  const path = to.split(/[?#]/)[0];
  if (path === "/dashboard") {
    return t("titles.home");
  }
  if (path === "/food" || path.startsWith("/food/")) {
    return t("food.title");
  }
  if (path.startsWith("/cart/")) {
    return t("food.cart_title");
  }
  if (path === "/trips") {
    return t("titles.trips");
  }
  return null;
}

/**
 * Apply a negative margin to move the 'back' button so it is visually aligned
 * with text along vertical margins. For example, '< BACK'
 * stacked on a heading 'My Page' would not align visually (the chevron would be
 * about 6 pixels to the right of an alignment with the 'M' in 'My Page').
 * This negative margin moves the chevron to the left to achieve vertical alignment.
 */
const ICON_OFFSET = -6;
