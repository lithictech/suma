import React from "react";

/**
 * Link that opens in a new window/tab, with safe rel attributes.
 *
 * Because opening a new window is a change of context, callers should pass
 * `newWindowLabel` (a localized string like "(opens in a new window)"),
 * which is added to the accessible name of the link
 * (visually hidden text, or appended to `aria-label` if one is given),
 * along with a small 'external link' icon.
 *
 * @param {string} href
 * @param {string=} className
 * @param children
 * @param {boolean=} opener If true, do not use rel=noopener.
 * @param {boolean=} referrer If true, do not use rel=noreferrer.
 * @param component Component to render, 'a' by default.
 * @param {string=} newWindowLabel Localized text warning that the link opens a new window.
 * @param {boolean=} noIcon If true, do not render the 'external link' icon.
 *   Use where the children are an image, icon, or button where the icon would break layout.
 * @param rest Passed to the component.
 */
export default function SafeExternalLink({
  href,
  className,
  children,
  opener,
  referrer,
  component: Component,
  newWindowLabel,
  noIcon,
  "aria-label": ariaLabel,
  ...rest
}) {
  Component = Component || "a";
  const hasLabel = typeof newWindowLabel === "string" && newWindowLabel.length > 0;
  const fullAriaLabel =
    ariaLabel && hasLabel ? `${ariaLabel} ${newWindowLabel}` : ariaLabel;
  return (
    <Component
      href={href}
      target="_blank"
      rel={[opener ? null : "noopener", referrer ? null : "noreferrer"]
        .filter(Boolean)
        .join(" ")}
      className={className}
      aria-label={fullAriaLabel}
      {...rest}
    >
      {children}
      {hasLabel && !ariaLabel && (
        <span className="visually-hidden"> {newWindowLabel}</span>
      )}
      {!noIcon && <i className="bi bi-box-arrow-up-right ms-1" aria-hidden="true" />}
    </Component>
  );
}
