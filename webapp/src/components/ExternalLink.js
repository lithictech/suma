import externalLinks from "../modules/externalLinks";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

/**
 * Like SafeExternalLink, but automatically allow referrer if
 * the href is in externalLinks.safeHosts.
 * @returns {JSX.Element}
 * @constructor
 */
export default function ExternalLink({ href, ...rest }) {
  const safe = href && externalLinks.safeHosts.some((h) => href.startsWith(h));
  return <SafeExternalLink referrer={safe} href={href} {...rest} />;
}
