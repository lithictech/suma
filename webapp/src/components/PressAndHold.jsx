import useLongPress from "../shared/react/useLongPress";
// Cannot use CSS modules due to animation
import "./PressAndHold.css";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

// If changing these, you MUST review the CSS.
const HOLD_SECS = 2;
const SIZE_RATIO = 0.7;

const HOLD_KEYS = ["Enter", " "];

/**
 * Button that must be pressed and held (mouse, touch, or keyboard)
 * for HOLD_SECS, and then released, before onHeld is called.
 *
 * The action runs on release (the up-event), not while the pointer is still
 * down, so it can be aborted after the hold completes by moving the pointer
 * off the button or moving focus away (WCAG 2.5.2 Pointer Cancellation).
 *
 * @param {number=} size
 * @param {function} onHeld
 * @param {string=} label Optional accessible name for the button.
 *   If not given, the name is computed from the children text.
 * @param {string=} releaseLabel Shown in place of the children,
 *   and announced, once the hold is complete ("Release to confirm").
 */
export default function PressAndHold({ size, onHeld, label, releaseLabel, children }) {
  size = size || 160;
  const innerSize = size * SIZE_RATIO;

  async function handleHeld() {
    buttonRef.current.disabled = true;
    try {
      await onHeld();
    } finally {
      buttonRef.current.disabled = false;
    }
  }

  // 'ready' means the hold time has elapsed and releasing will run the action.
  const [ready, setReady] = React.useState(false);
  const readyRef = React.useRef(false);
  const markReady = React.useCallback(() => {
    readyRef.current = true;
    setReady(true);
  }, []);
  const isPressed = useLongPress(markReady, HOLD_SECS * 1000);

  const buttonRef = React.useRef(null);

  // Stop the hold without running the action.
  const cancel = () => {
    readyRef.current = false;
    setReady(false);
    isPressed.turnOff();
  };
  // The up-event: run the action only if the hold had completed.
  const release = () => {
    const wasReady = readyRef.current;
    cancel();
    if (wasReady) {
      handleHeld().then(null);
    }
  };

  // Keyboard users hold Space or Enter, same as holding the mouse/touch.
  // Ignore auto-repeat so the timer is only started once per hold.
  const handleKeyDown = (e) => {
    if (!HOLD_KEYS.includes(e.key)) {
      return;
    }
    e.preventDefault();
    if (!e.repeat) {
      isPressed.turnOn();
    }
  };
  const handleKeyUp = (e) => {
    if (!HOLD_KEYS.includes(e.key)) {
      return;
    }
    e.preventDefault();
    release();
  };

  return (
    <div
      className="position-relative d-flex align-items-center justify-content-center mt-0"
      style={{ height: size + 8 }}
    >
      <div className="position-absolute d-block" style={{ width: size, height: size }}>
        <div
          className={clsx(
            "press-and-hold-feedback",
            isPressed.isOn && !ready && "press-and-hold-feedback-active",
            ready && "press-and-hold-feedback-ready"
          )}
          style={{ width: size, height: size }}
        />
      </div>
      <Button
        type="button"
        variant="primary"
        ref={buttonRef}
        className="position-absolute press-and-hold-button"
        style={{ width: innerSize, height: innerSize }}
        aria-label={label}
        onMouseDown={isPressed.turnOn}
        onMouseUp={release}
        onMouseLeave={cancel}
        onTouchStart={isPressed.turnOn}
        onTouchEnd={release}
        onTouchCancel={cancel}
        onKeyDown={handleKeyDown}
        onKeyUp={handleKeyUp}
        onBlur={cancel}
      >
        <span className="press-and-hold-label">
          {ready && releaseLabel ? releaseLabel : children}
        </span>
      </Button>
      <span role="status" className="visually-hidden">
        {ready && releaseLabel ? releaseLabel : ""}
      </span>
    </div>
  );
}
