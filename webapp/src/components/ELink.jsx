import ExternalLink from "./ExternalLink";
import React from "react";
import { Link } from "react-router-dom";

/**
 * Use this where we don't know if we have an internal or external link.
 *
 * If the link starts with `/` or "#" we use Link,
 * otherwise we use ExternalLink.
 *
 * There are some special behaviors available as well:
 * - If link is local, and includes ##, then replace the current URL.
 * - If the link text includes __blank__ anywhere, then use an external link with target=_blank.
 *
 * @param {string} href Same as `to`.
 * @param {string} to Same as react-router-dom Link#to.
 * @param {boolean} immediate If true, prevent the default mousedown behavior,
 *   so the currently focused element is not blurred before the click navigates.
 *   This allows the caller to bypass things like blur events that happen
 *   during form validation, while still navigating on the normal click
 *   (so the pointer action can be cancelled by moving off the link).
 *   This is only relevant for local URLs.
 * @param rest
 * @returns {JSX.Element}
 * @constructor
 */
export default function ELink({ href, to, immediate, ...rest }) {
  const u = href || to || "";
  if (u.includes("__blank__")) {
    const clean = u.replace("__blank__", "");
    return <ExternalLink href={clean} {...rest} />;
  }
  if (u.startsWith("/") || u.startsWith("#")) {
    let to, replace;
    if (immediate) {
      rest = {
        onMouseDown: (e) => e.preventDefault(),
        ...rest,
      };
    }
    if (u.includes("##")) {
      to = u.replace("##", "#");
      replace = true;
    } else {
      to = u;
      replace = u.startsWith("##");
    }
    return <Link to={to} replace={replace} {...rest} />;
  }
  return <ExternalLink href={u} {...rest} />;
}
