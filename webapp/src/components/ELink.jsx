import ExternalLink from "./ExternalLink";
import React from "react";
import { Link, useNavigate } from "react-router-dom";

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
 * @param {boolean} immediate If true, navigate directly using onPointerDown,
 *   rather than the default behavior of onClick. This allows the caller to bypass
 *   things like blur events that happen during form validation.
 *   This is only relevant for local URLs.
 * @param rest
 * @returns {JSX.Element}
 * @constructor
 */
export default function ELink({ href, to, immediate, ...rest }) {
  const navigate = useNavigate();
  const u = href || to || "";
  if (u.includes("__blank__")) {
    const clean = u.replace("__blank__", "");
    return <ExternalLink href={clean} {...rest} />;
  }
  if (u.startsWith("/") || u.startsWith("#")) {
    if (immediate) {
      rest = { onPointerDown: (e) => navigate(e.target.attributes.href.value), ...rest };
    }
    if (u.includes("##")) {
      return <Link to={u.replace("##", "#")} replace {...rest} />;
    }
    return <Link to={u} replace={u.startsWith("##")} {...rest} />;
  }
  return <ExternalLink href={u} {...rest} />;
}
