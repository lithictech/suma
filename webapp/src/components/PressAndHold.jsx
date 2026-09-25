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
 * for HOLD_SECS before onHeld is called.
 *
 * @param {number=} size
 * @param {function} onHeld
 * @param {string=} label Optional accessible name for the button.
 *   If not given, the name is computed from the children text.
 */
export default function PressAndHold({ size, onHeld, label, children }) {
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

  const isPressed = useLongPress(() => {
    handleHeld().then(null);
  }, HOLD_SECS * 1000);

  const buttonRef = React.useRef(null);

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
    isPressed.turnOff();
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
            isPressed.isOn && "press-and-hold-feedback-active"
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
        onMouseUp={isPressed.turnOff}
        onMouseLeave={isPressed.turnOff}
        onTouchStart={isPressed.turnOn}
        onTouchEnd={isPressed.turnOff}
        onTouchCancel={isPressed.turnOff}
        onKeyDown={handleKeyDown}
        onKeyUp={handleKeyUp}
        onBlur={isPressed.turnOff}
      >
        <span className="press-and-hold-label">{children}</span>
      </Button>
    </div>
  );
}
