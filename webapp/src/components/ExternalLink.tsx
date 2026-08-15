import externalLinks from "../modules/externalLinks";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

interface ExternalLinkProps {
  href?: string;
  [rest: string]: any;
}

/**
 * Like SafeExternalLink, but automatically allow referrer if
 * the href is in externalLinks.safeHosts.
 */
export default function ExternalLink({ href, ...rest }: ExternalLinkProps) {
  const safe = !!(href && externalLinks.safeHosts.some((h) => href.startsWith(h)));
  return <SafeExternalLink referrer={safe} href={href || ""} {...rest} />;
}
