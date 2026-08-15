import clsx from "clsx";
import React from "react";

interface AlertProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: string;
  show?: boolean;
  dismissible?: boolean;
  onClose?: () => void;
}

// TODO(bootstrap-removal): dismissible close button and variant colors are
// unstyled placeholders pending the real Alert design in ui/.
export default function Alert({
  variant,
  show = true,
  dismissible,
  onClose,
  className,
  children,
  ...rest
}: AlertProps) {
  if (!show) {
    return null;
  }
  const cls = clsx("alert", variant && `alert-${variant}`, className);
  return (
    <div className={cls} {...rest}>
      {children}
      {dismissible && (
        <button
          type="button"
          className="alert-close"
          aria-label="Close"
          onClick={onClose}
        >
          ×
        </button>
      )}
    </div>
  );
}
