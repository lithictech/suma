import Button from "./Button.jsx";
import "./Dialog.css";
import React from "react";

// export interface DialogProps {
//   open: boolean;
//   onClose: () => void;
//   /** id of the element within `children` that labels the dialog (e.g. a heading's id) */
//   labelledBy: string;
//   /**
//    * Ref to the element that should receive focus when the dialog opens —
//    * typically a ref you're already holding on your accept/confirm button.
//    * If omitted, the browser falls back to its own default (first focusable element).
//    */
//   initialFocusRef?: RefObject<HTMLElement>;
//   /** Any content — a Card, a form, plain text. Dialog adds no chrome of its own besides the close button. */
//   children: ComponentChildren;
//   className?: string;
// }

export function Dialog({
  open,
  onClose,
  labelledBy,
  initialFocusRef,
  children,
  className,
}) {
  const dialogRef = React.useRef(null);

  // Drive the native dialog's open/closed state from the `open` prop.
  // showModal()/close() are what give us focus trapping, Escape-to-close,
  // and an inert background — all built into the browser.
  React.useEffect(() => {
    const dialog = dialogRef.current;
    if (!dialog) return;

    if (open && !dialog.open) {
      dialog.showModal();
      // showModal() already moves focus somewhere inside the dialog;
      // override it if the caller told us specifically where it should go.
      initialFocusRef?.current?.focus();
    } else if (!open && dialog.open) {
      dialog.close();
    }
  }, [open, initialFocusRef]);

  // The native 'close' event fires both on Escape and on .close() calls —
  // listening here keeps the caller's controlled `open` state in sync
  // with however the dialog actually closed.
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

      {/* Purely a click boundary: stopping propagation here means only a
          genuine backdrop click (outside this div) reaches onClick above. */}
      <div onClick={(e) => e.stopPropagation()}>{children}</div>
    </dialog>
  );
}
