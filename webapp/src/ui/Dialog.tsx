import "./Dialog.css";
import React from "react";

export interface DialogProps {
  open: boolean;
  onClose: () => void;
  /** id of the element within `children` that labels the dialog (e.g. a heading's id) */
  labelledBy: string;
  /**
   * Ref to the element that should receive focus when the dialog opens —
   * typically a ref you're already holding on your accept/confirm button.
   * If omitted, the browser falls back to its own default (first focusable element).
   */
  initialFocusRef?: React.RefObject<HTMLElement>;
  /** Any content — a Card, a form, plain text. Dialog adds no chrome of its own besides the close button. */
  children?: React.ReactNode;
  className?: string;
}

export function Dialog({
  open,
  onClose,
  labelledBy,
  initialFocusRef,
  children,
  className,
}: DialogProps) {
  const dialogRef = React.useRef<HTMLDialogElement>(null);

  React.useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    if (open && !dialog.open) {
      dialog.showModal();
      initialFocusRef?.current?.focus();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open, initialFocusRef]);

  React.useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;
    const handleClose = () => onClose();
    dialog.addEventListener("close", handleClose);
    return () => dialog.removeEventListener("close", handleClose);
  }, [onClose]);

  return (
    <dialog
      ref={dialogRef}
      className={["dialog", className].filter(Boolean).join(" ")}
      aria-labelledby={labelledBy}
      onClick={onClose}
    >
      <button
        role="button"
        className="dialog-close"
        aria-label="Close"
        onClick={(e) => {
          e.stopPropagation();
          onClose();
        }}
      >
        ×
      </button>
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </dialog>
  );
}
