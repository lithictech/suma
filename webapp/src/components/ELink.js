import ExternalLink from "./ExternalLink";
import React from "react";
import { Link } from "react-router-dom";

/**
 * Use this where we don't know if we have an internal or external link.
 * If the link starts with `/` or "#" we use Link,
 * otherwise we use ExternalLink.
 * @returns {JSX.Element}
 * @constructor
 */
export default function ELink({ href, to, ...rest }) {
  const u = href || to || "";
  if (u.startsWith("/") || u.startsWith("#")) {
    if (u.includes("##")) {
      return <Link to={u.replace("##", "#")} replace {...rest} />;
    }
    return <Link to={u} replace={u.startsWith("##")} {...rest} />;
  }
  return <ExternalLink href={u} {...rest} />;
}
