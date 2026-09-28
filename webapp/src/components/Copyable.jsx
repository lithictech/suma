import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

/**
 * Render text with a button to copy it to the clipboard.
 * After copying, a status message is shown next to the button.
 * The message has no time limit (WCAG 2.2.3): it stays until the component unmounts.
 * Copying again re-announces the message.
 */
export default function Copyable({ className, children, inline, text }) {
  // Count copies so the status is re-rendered (and announced again) on each copy.
  const [copyCount, setCopyCount] = React.useState(0);
  function onCopy(e) {
    e.preventDefault();
    navigator.clipboard.writeText(text || children);
    setCopyCount((c) => c + 1);
  }
  return (
    <div className={clsx(inline && "d-inline text-nowrap", className)}>
      {children || text}
      <Button
        variant="link"
        className={clsx(inline && "p-0 ps-2", "a11y-target-min")}
        onClick={onCopy}
        aria-label={t("common.copy")}
      >
        <i className="bi bi-clipboard2-fill" aria-hidden="true"></i>
      </Button>
      {/* The (empty) status region is always present so the message is announced. */}
      <span role="status">
        {copyCount > 0 && (
          <span key={copyCount} className="ms-2">
            {t("common.copied_to_clipboard")}
          </span>
        )}
      </span>
    </div>
  );
}
