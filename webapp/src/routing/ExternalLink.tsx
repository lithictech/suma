import React from "react";

type SafeHost = string;

const safeHosts: SafeHost[] = ["https://mysuma.org"];

interface ExternalLinkProps extends React.HTMLAttributes<HTMLAnchorElement> {
  href: string;
}

export default function ExternalLink({ href, ...rest }: ExternalLinkProps) {
  let rel = "noopener";
  const safe = !!(href && safeHosts.some((h) => href.startsWith(h)));
  if (!safe) {
    rel += " noreferrer";
  }
  return (
    // eslint-disable-next-line react/jsx-no-target-blank
    <a href={href} target="_blank" rel={rel} {...rest} />
  );
}
