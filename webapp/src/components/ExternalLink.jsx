import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import SafeExternalLink from "../shared/react/SafeExternalLink";
import React from "react";

/**
 * Like SafeExternalLink, but automatically allow referrer if
 * the href is in externalLinks.safeHosts.
 *
 * Since the link opens in a new window, it includes localized
 * '(opens in a new window)' text for assistive technology, and an icon
 * (pass `noIcon` to skip the icon, like for icon-only or image links).
 * @returns {JSX.Element}
 * @constructor
 */
export default function ExternalLink({ href, ...rest }) {
  const safe = href && externalLinks.safeHosts.some((h) => href.startsWith(h));
  return (
    <SafeExternalLink
      referrer={safe}
      href={href}
      newWindowLabel={t("common.opens_new_window")}
      {...rest}
    />
  );
}
